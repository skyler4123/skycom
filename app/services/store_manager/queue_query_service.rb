# frozen_string_literal: true

# StoreManager::QueueQueryService — the whole-day fulfilment queue.
#
# Open means "not handed over by the end of the selected branch day"; completed
# means "handed over before the end of that day". That lets yesterday's queue
# and close report survive today's handovers.
#
# Text search uses Meilisearch for order text and customer names; exact codes are
# resolved in the database. Channel and status labels are mapped to enums so a
# manager can search "Click & Collect" or "Ready".
#
# Docs: docs/MEILISEARCH.md, docs/business_analysis/06-store-manager.md
class StoreManager::QueueQueryService
  PAGE_SIZE = 50
  SEARCH_MAX_IDS = 1000
  FULFILLMENT_CHANNELS = %w[click_collect local_delivery phone_hold].freeze
  CANCELLED_STATUSES = %w[cancelled refunded].freeze

  CHANNEL_LABELS = {
    "click_collect" => [ "click & collect", "click and collect", "click collect", "pickup", "pick up" ],
    "local_delivery" => [ "local delivery", "delivery" ],
    "phone_hold" => [ "phone hold", "phone" ]
  }.freeze

  FULFILLMENT_LABELS = {
    "ready" => [ "ready" ],
    "unfulfilled" => [ "unfulfilled", "not ready" ],
    "handed_over" => [ "handed over", "completed", "complete" ]
  }.freeze

  PAYMENT_LABELS = {
    "paid" => [ "paid" ],
    "pending" => [ "pending", "unpaid" ]
  }.freeze

  def self.call(company:, branch:, date:, now: Time.current, tab: "all", q: nil, page: 1, read_only: false)
    new(
      company: company, branch: branch, date: date, now: now,
      tab: tab, q: q, page: page, read_only: read_only
    ).call
  end

  # Every order still open at the end of the day, for the close report. Not
  # paginated: the report must not hide a handover behind page two.
  def self.open_handovers(company:, branch:, date:, now: Time.current)
    new(
      company: company, branch: branch, date: date, now: now,
      tab: "all", q: nil, page: 1, read_only: true
    ).open_handovers
  end

  def initialize(company:, branch:, date:, now:, tab:, q:, page:, read_only:)
    @company = company
    @branch = branch
    @date = date.to_date
    @now = now
    @tab = %w[all click_collect local_delivery completed].include?(tab.to_s) ? tab.to_s : "all"
    @query = q.to_s.strip
    @page = page.to_i.positive? ? page.to_i : 1
    @read_only = read_only
  end

  def call
    {
      orders: serialized_rows,
      counts: counts_payload,
      day_counts: day_counts_payload,
      pagination: pagination_payload,
      tab: tab,
      search_capped: search_capped?
    }
  end

  def open_handovers
    open_scope(base_scope).order(created_at: :asc).map do |order|
      {
        code: order.code.presence || "ORD-#{order.id.to_s.last(8).upcase}",
        customer_name: order.customer&.name.presence || order.name.presence || "Walk-in customer",
        fulfillment_status: order.fulfillment_status,
        fulfillment_label: fulfillment_for(order)[:label],
        payment_status: paid?(order) ? "paid" : "unpaid"
      }
    end
  end

  private

  attr_reader :company, :branch, :date, :now, :tab, :query, :page, :read_only

  def day_range
    @day_range ||= LocalTime.day_range(date, branch)
  end

  def day_end
    @day_end ||= day_range.end
  end

  def cancelled_statuses
    Order.workflow_statuses.values_at(*CANCELLED_STATUSES)
  end

  def base_scope
    @base_scope ||= company.orders
      .where(branch_id: branch.id, created_at: day_range, discarded_at: nil)
      .where(fulfillment_channel: FULFILLMENT_CHANNELS)
      .where.not(workflow_status: cancelled_statuses)
      .includes(
        :customer,
        :employee,
        :invoices,
        :order_product_appointments,
        :order_service_appointments,
        :order_product_group_appointments,
        :order_service_group_appointments,
        :order_subscription_plan_appointments
      )
  end

  def open_scope(scope = searched_scope)
    scope.where("orders.handed_over_at IS NULL OR orders.handed_over_at >= ?", day_end)
  end

  def completed_scope(scope = searched_scope)
    scope.where("orders.handed_over_at IS NOT NULL AND orders.handed_over_at < ?", day_end)
  end

  def tab_scope
    case tab
    when "completed"
      completed_scope
    when "click_collect"
      open_scope.where(fulfillment_channel: :click_collect)
    when "local_delivery"
      open_scope.where(fulfillment_channel: :local_delivery)
    else
      open_scope
    end
  end

  def counts_payload
    @counts_payload ||= begin
      open = open_scope
      {
        all: open.count,
        click_collect: open.where(fulfillment_channel: :click_collect).count,
        local_delivery: open.where(fulfillment_channel: :local_delivery).count,
        phone_hold: open.where(fulfillment_channel: :phone_hold).count,
        completed: completed_scope.count
      }
    end
  end

  def day_counts_payload
    @day_counts_payload ||= begin
      open = open_scope(base_scope)
      {
        all: open.count,
        click_collect: open.where(fulfillment_channel: :click_collect).count,
        local_delivery: open.where(fulfillment_channel: :local_delivery).count,
        phone_hold: open.where(fulfillment_channel: :phone_hold).count,
        completed: completed_scope(base_scope).count
      }
    end
  end

  def pagination_payload
    total = tab_scope.count
    pages = total.zero? ? 0 : (total.to_f / PAGE_SIZE).ceil
    current_page = pages.positive? ? [ page, pages ].min : 1
    offset = (current_page - 1) * PAGE_SIZE
    {
      page: current_page,
      per_page: PAGE_SIZE,
      pages: pages,
      count: total,
      from: total.zero? ? 0 : offset + 1,
      to: total.zero? ? 0 : [ offset + PAGE_SIZE, total ].min,
      previous: current_page > 1 ? current_page - 1 : nil,
      next: pages.positive? && current_page < pages ? current_page + 1 : nil
    }
  end

  def rows
    @rows ||= begin
      offset = (pagination_payload[:page] - 1) * PAGE_SIZE
      tab_scope.order(created_at: :desc).offset(offset).limit(PAGE_SIZE).to_a
    end
  end

  def serialized_rows
    rows.map { |order| serialize_order(order) }
  end

  def serialize_order(order)
    invoice = latest_invoice(order)
    total_cents = invoice ? invoice_total_cents(invoice) : nil
    paid = paid?(order)
    channel = channel_for(order)
    fulfillment = fulfillment_for(order)
    handed_over = order.fulfillment_status_handed_over?
    can_mark_ready = !read_only && !handed_over && order.fulfillment_status != "ready"
    can_hand_over = !read_only && !handed_over && paid

    {
      id: order.id,
      code: order.code.presence || "ORD-#{order.id.to_s.last(8).upcase}",
      customer_name: order.customer&.name.presence || order.name.presence || "Walk-in customer",
      customer_meta: customer_meta(order),
      placed_at: LocalTime.utc_iso(order.created_at),
      items_count: items_count(order),
      total_cents: total_cents,
      invoice_code: invoice&.code,
      currency: order.currency || company.currency || "usd",
      business_type: order.business_type,
      channel_key: channel[:key],
      channel_label: channel[:label],
      channel_icon: channel[:icon],
      fulfillment_status: order.fulfillment_status,
      fulfillment_label: fulfillment[:label],
      fulfillment_tone: fulfillment[:tone],
      payment_status: paid ? "paid" : "unpaid",
      payment_label: paid ? "Paid" : "Unpaid",
      workflow_status: order.workflow_status,
      assignment: order.employee&.name.presence || "Unassigned",
      handed_over_at: LocalTime.utc_iso(order.handed_over_at),
      can_mark_ready: can_mark_ready,
      can_hand_over: can_hand_over,
      hand_over_blocked_reason: (!paid && !handed_over) ? "Payment due at POS" : nil,
      order_path: "/companies/#{company.id}/orders/#{order.id}"
    }
  end

  def channel_for(order)
    case order.fulfillment_channel
    when "click_collect"
      { key: "click_collect", label: "Click & Collect", icon: "store" }
    when "local_delivery"
      { key: "local_delivery", label: "Local Delivery", icon: "local_shipping" }
    when "phone_hold"
      { key: "phone_hold", label: "Phone Hold", icon: "lock_clock" }
    else
      { key: "walk_in", label: "Walk-in", icon: "point_of_sale" }
    end
  end

  def fulfillment_for(order)
    case order.fulfillment_status
    when "ready"
      { label: "Ready", tone: "success" }
    when "handed_over"
      { label: "Handed over", tone: "muted" }
    else
      { label: "Unfulfilled", tone: "warning" }
    end
  end

  def latest_invoice(order)
    order.invoices.max_by(&:created_at)
  end

  def invoice_total_cents(invoice)
    total = invoice.total_cents.to_i
    total.positive? ? total : invoice.price_cents.to_i
  end

  def paid?(order)
    return true if order.workflow_status_paid? || order.workflow_status_completed?

    order.invoices.any?(&:payment_status_paid?)
  end

  def items_count(order)
    order.line_items.sum { |item| item.quantity.to_i }
  end

  def customer_meta(order)
    return "Walk-in customer" if order.customer.blank?

    order.customer.email.presence || order.customer.phone_number.presence || "Registered customer"
  end

  # --- Search -----------------------------------------------------------------

  def searched_scope
    @searched_scope ||= build_search_scope
  end

  def build_search_scope
    return base_scope if query.blank?

    exact = base_scope.find_by("UPPER(orders.code) = ?", query.upcase)
    return base_scope.where(id: exact.id) if exact.present?

    channel_keys = enum_keys_for(query, CHANNEL_LABELS)
    fulfillment_keys = enum_keys_for(query, FULFILLMENT_LABELS)
    payment_keys = enum_keys_for(query, PAYMENT_LABELS)
    meili_ids = meilisearch_order_ids
    customer_order_ids = meilisearch_customer_order_ids

    relation = base_scope.where(id: (meili_ids + customer_order_ids).uniq)
    relation = relation.or(base_scope.where(fulfillment_channel: channel_keys)) if channel_keys.any?
    relation = relation.or(base_scope.where(fulfillment_status: fulfillment_keys)) if fulfillment_keys.any?
    relation = relation.or(base_scope.where(workflow_status: payment_keys)) if payment_keys.any?

    if meili_ids.empty? && customer_order_ids.empty? && channel_keys.empty? && fulfillment_keys.empty? && payment_keys.empty?
      base_scope.none
    else
      relation
    end
  end

  def meilisearch_order_ids
    result = Order.ms_raw_search(
      query,
      filter: %(company_id = "#{company.id}" AND branch_id = "#{branch.id}"),
      attributes_to_search_on: %w[code name description],
      hits_per_page: SEARCH_MAX_IDS
    )
    ids = result.fetch("hits", []).map { |hit| hit["id"] }
    @search_capped = true if ids.length >= SEARCH_MAX_IDS
    ids
  end

  def meilisearch_customer_order_ids
    result = Customer.ms_raw_search(
      query,
      filter: %(company_id = "#{company.id}"),
      attributes_to_search_on: %w[name email phone_number code],
      hits_per_page: SEARCH_MAX_IDS
    )
    customer_ids = result.fetch("hits", []).map { |hit| hit["id"] }
    @search_capped = true if customer_ids.length >= SEARCH_MAX_IDS
    return [] if customer_ids.empty?

    base_scope.where(customer_id: customer_ids).pluck(:id)
  end

  def enum_keys_for(value, labels)
    normalized = value.to_s.downcase.gsub(/[^a-z0-9& ]/, " ").squish
    labels.filter_map do |key, phrases|
      key if phrases.any? { |phrase| normalized.include?(phrase) }
    end
  end

  def search_capped?
    @search_capped == true
  end
end
