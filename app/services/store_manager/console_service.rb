# frozen_string_literal: true

# StoreManager::ConsoleService — builds the live store manager console payload
# for a branch appointment.
#
# Why it exists: the Store Manager operation is the branch-level command screen
# for retail floor operations. It combines today's sales, the fulfillment queue,
# shelf replenishment alerts, register activity and the on-duty roster so a
# manager can run the store from one page.
#
# How it works: derives every value from existing domain tables — Order for the
# sales/fulfillment/register numbers, Stock for shelf alerts, Employee for the
# roster. Footfall sensors are not modelled yet; the payload reports
# `footfall.connected = false` and exposes hourly order volume instead of
# inventing visitor counts.
#
# Docs: docs/OPERATIONS.md, docs/STOCK.md, docs/ORDER_PROCESSING_V1.md
class StoreManager::ConsoleService
  ORDER_LIMIT = 8
  REPLENISHMENT_LIMIT = 8
  STAFF_LIMIT = 8
  OPEN_HOUR = 8
  CLOSE_HOUR = 18
  FULFILLMENT_STATUSES = %w[draft pending confirmed in_progress].freeze
  SOLD_STATUSES = %w[paid completed].freeze

  def self.call(company:, appointment:, now: Time.current)
    new(company: company, appointment: appointment, now: now).call
  end

  def initialize(company:, appointment:, now:)
    @company = company
    @appointment = appointment
    @branch = appointment.branch
    @now = now
  end

  def call
    {
      branch: branch_payload,
      currency: company.currency || "usd",
      kpis: kpis,
      orders: orders_payload,
      orders_total: today_orders_count,
      order_counts: order_counts_payload,
      replenishments: replenishments_payload,
      registers: registers_payload,
      staff: staff_payload,
      hourly: hourly_payload,
      footfall: footfall_payload,
      generated_at: now.iso8601
    }
  end

  private

  attr_reader :company, :appointment, :branch, :now

  def branch_payload
    {
      id: branch.id,
      name: branch.name,
      code: branch.code,
      phone_number: branch.phone_number
    }
  end

  def todays_orders
    @todays_orders ||= orders_scope(today_range).to_a
  end

  def yesterdays_orders
    @yesterdays_orders ||= orders_scope(yesterday_range).to_a
  end

  def today_range
    now.beginning_of_day..now.end_of_day
  end

  def yesterday_range
    (now.beginning_of_day - 1.day)..(now.end_of_day - 1.day)
  end

  def base_orders_scope(range)
    company.orders
      .where(branch_id: branch.id, created_at: range, discarded_at: nil)
      .where.not(workflow_status: cancelled_status_values)
  end

  def orders_scope(range)
    base_orders_scope(range)
      .includes(
        :customer,
        :employee,
        :order_product_appointments,
        :order_service_appointments,
        :order_product_group_appointments,
        :order_service_group_appointments,
        :order_subscription_plan_appointments
      )
      .order(created_at: :desc)
      .limit(200)
  end

  def today_orders_count
    @today_orders_count ||= base_orders_scope(today_range).count
  end

  def order_counts_payload
    @order_counts_payload ||= begin
      scope = base_orders_scope(today_range)
      {
        all: scope.count,
        click_collect: scope.where(business_type: :in_store).count,
        delivery: scope.where(business_type: :online).count,
        completed: scope.where(workflow_status: sold_status_values).count
      }
    end
  end

  def cancelled_status_values
    Order.workflow_statuses.values_at("cancelled", "refunded")
  end

  def sold_status_values
    Order.workflow_statuses.values_at(*SOLD_STATUSES)
  end

  def fulfillment_status_values
    Order.workflow_statuses.values_at(*FULFILLMENT_STATUSES)
  end

  def sold_orders(orders)
    orders.select { |order| SOLD_STATUSES.include?(order.workflow_status) }
  end

  def fulfillment_count
    @fulfillment_count ||= base_orders_scope(today_range)
      .where(workflow_status: fulfillment_status_values)
      .count
  end

  def fulfillment_channel_count(business_type)
    base_orders_scope(today_range)
      .where(workflow_status: fulfillment_status_values, business_type: business_type)
      .count
  end

  def kpis
    current_sales = sold_orders(todays_orders).sum { |order| order_total_cents(order) }
    previous_sales = sold_orders(yesterdays_orders).sum { |order| order_total_cents(order) }

    {
      gross_sales_cents: current_sales,
      previous_gross_sales_cents: previous_sales,
      gross_sales_delta_pct: percentage_change(current_sales, previous_sales),
      transactions_count: base_orders_scope(today_range).where(workflow_status: sold_status_values).count,
      active_pos_counters: registers_payload.length,
      orders_to_fulfill: fulfillment_count,
      click_collect_count: fulfillment_channel_count(:in_store),
      delivery_count: fulfillment_channel_count(:online),
      shelf_alerts: shelf_alerts_count,
      staff_on_duty: staff_on_duty_count
    }
  end

  def shelf_alerts_count
    @shelf_alerts_count ||= low_stock_scope.count
  end

  def staff_on_duty_count
    @staff_on_duty_count ||= company.employees
      .where(branch_id: branch.id, discarded_at: nil)
      .where(lifecycle_status: :active)
      .count
  end

  def orders_payload
    @orders_payload ||= todays_orders.first(ORDER_LIMIT).map { |order| order_payload(order) }
  end

  def order_payload(order)
    channel = channel_for(order)
    status = status_for(order)

    {
      id: order.id,
      code: order.code.presence || "ORD-#{order.id.to_s.first(8).upcase}",
      customer_name: order.customer&.name.presence || order.name.presence || "Walk-in customer",
      customer_meta: customer_meta(order),
      placed_at: order.created_at.strftime("%-I:%M %p"),
      items_count: items_count(order),
      total_cents: order_total_cents(order),
      currency: order.currency || company.currency || "usd",
      business_type: order.business_type,
      channel: channel[:key],
      channel_label: channel[:label],
      channel_icon: channel[:icon],
      workflow_status: order.workflow_status,
      status_label: status[:label],
      status_tone: status[:tone],
      assignment: order.employee&.name.presence || "Unassigned",
      action_key: action_for(order)[:key],
      action_label: action_for(order)[:label],
      order_path: "/companies/#{company.id}/orders/#{order.id}"
    }
  end

  def channel_for(order)
    case order.business_type
    when "in_store"
      { key: "click_collect", label: "Click & Collect", icon: "store" }
    when "online"
      { key: "delivery", label: "Local Delivery", icon: "local_shipping" }
    else
      { key: "phone_hold", label: "Phone Hold", icon: "lock_clock" }
    end
  end

  def status_for(order)
    case order.workflow_status
    when "draft", "pending"
      { label: "Awaiting Picking", tone: "warning" }
    when "confirmed"
      { label: "Ready for Pickup", tone: "success" }
    when "in_progress"
      { label: "Picking in Progress", tone: "info" }
    when "paid", "completed"
      { label: "Completed", tone: "success" }
    when "shipped"
      { label: "Out for Delivery", tone: "info" }
    else
      { label: order.workflow_status.to_s.humanize, tone: "muted" }
    end
  end

  def action_for(order)
    case order.workflow_status
    when "draft", "pending"
      { key: "start", label: "Start Fulfillment" }
    when "confirmed"
      { key: "handover", label: "Handover to Customer" }
    when "in_progress"
      { key: "verify", label: "Verify Packing" }
    else
      { key: "view", label: "View Order" }
    end
  end

  def customer_meta(order)
    return "Walk-in customer" if order.customer.blank?
    return "VIP customer" if order.customer.property_boolean_1

    order.customer.email.presence || order.customer.phone_number.presence || "Registered customer"
  end

  def items_count(order)
    order.line_items.sum { |item| item.quantity.to_i }
  end

  def order_total_cents(order)
    (order.line_items.sum { |item| item.total_price.to_d } * 100).round
  end

  def low_stock_scope
    company.stocks
      .where(branch_id: branch.id, discarded_at: nil)
      .where("quantity - pending <= ?", LOW_STOCK_THRESHOLD)
  end

  def low_stock_stocks
    @low_stock_stocks ||= low_stock_scope
      .includes(:product, :warehouse)
      .order(Arel.sql("(quantity - pending) ASC"))
      .limit(REPLENISHMENT_LIMIT)
      .to_a
  end

  def warehouse_availability
    @warehouse_availability ||= begin
      product_ids = low_stock_stocks.map(&:product_id)
      return {} if product_ids.empty?

      company.stocks
        .where(product_id: product_ids, discarded_at: nil)
        .where.not(id: low_stock_stocks.map(&:id))
        .group(:product_id)
        .sum(Arel.sql("GREATEST(quantity - pending, 0)"))
    end
  end

  def replenishments_payload
    @replenishments_payload ||= low_stock_stocks.map do |stock|
      available = [ stock.quantity - stock.pending, 0 ].max
      stage = replenishment_stage(stock, available)

      {
        id: stock.id,
        product_name: stock.product&.name.presence || stock.name.presence || "Stock item",
        sku: stock.code.presence || stock.product&.code.presence || "—",
        bay: stock.property_integer_3.presence,
        shelf_quantity: available,
        on_hand: stock.quantity,
        pending: stock.pending,
        threshold: LOW_STOCK_THRESHOLD,
        warehouse_available: warehouse_availability[stock.product_id].to_i,
        warehouse_name: stock.warehouse&.name.presence || "Central warehouse",
        stage: stage[:key],
        stage_label: stage[:label],
        stage_icon: stage[:icon],
        action_key: stage[:action_key],
        action_label: stage[:action_label],
        stock_path: "/companies/#{company.id}/stocks/#{stock.id}"
      }
    end
  end

  def replenishment_stage(stock, available)
    if available <= 0
      {
        key: "empty",
        label: "Empty shelf",
        icon: "error",
        action_key: "request",
        action_label: "Request Restock"
      }
    elsif stock.pending.positive?
      {
        key: "reserved",
        label: "Reserved for orders",
        icon: "pending_actions",
        action_key: "request",
        action_label: "Request Restock"
      }
    else
      {
        key: "low",
        label: "Below threshold",
        icon: "trending_down",
        action_key: "request",
        action_label: "Request Restock"
      }
    end
  end

  def registers_payload
    @registers_payload ||= begin
      groups = todays_orders.reject { |order| order.employee_id.nil? }.group_by(&:employee)

      groups.map.with_index do |(employee, orders), index|
        {
          id: employee.id,
          number: format("%02d", index + 1),
          name: register_name(index),
          cashier: employee.name,
          role: employee_role(employee) || "Cashier",
          sales_cents: sold_orders(orders).sum { |order| order_total_cents(order) },
          orders_count: orders.length,
          currency: employee.currency || company.currency || "usd",
          status: "active"
        }
      end
    end
  end

  def register_name(index)
    case index
    when 0 then "Main Counter"
    when 1 then "Express Kiosk"
    when 2 then "Pickup Desk"
    else "Floor Register"
    end
  end

  def employee_role(employee)
    role = employee.category&.name.presence
    return nil if role.blank? || role == "Employees"

    role
  end

  def staff_scope
    @staff_scope ||= company.employees
      .where(branch_id: branch.id, discarded_at: nil)
      .where(lifecycle_status: :active)
      .includes(:category)
      .order(:name)
      .limit(STAFF_LIMIT)
      .to_a
  end

  def staff_payload
    register_employee_ids = registers_payload.map { |register| register[:id] }

    staff_scope.map do |employee|
      status = if register_employee_ids.include?(employee.id)
        { key: "pos", label: "Active POS", tone: "success" }
      else
        { key: "duty", label: "On Duty", tone: "primary" }
      end

      {
        id: employee.id,
        name: employee.name,
        role: employee_role(employee) || "Store staff",
        code: employee.code.presence || "—",
        status_key: status[:key],
        status_label: status[:label],
        status_tone: status[:tone]
      }
    end
  end

  def hourly_payload
    (OPEN_HOUR..CLOSE_HOUR).map do |hour|
      bucket = todays_orders.select { |order| order.created_at.hour == hour }
      {
        hour: hour,
        label: format("%02dh", hour),
        orders_count: bucket.length,
        revenue_cents: bucket.sum { |order| order_total_cents(order) }
      }
    end
  end

  def footfall_payload
    buyers = todays_orders.map(&:customer_id).compact.uniq.length

    {
      connected: false,
      visitors: nil,
      buyers: buyers,
      conversion_pct: nil,
      note: "Footfall sensor is not connected for this branch."
    }
  end

  def percentage_change(current, previous)
    return nil if previous.blank? || previous.to_d.zero?

    (((current.to_d - previous.to_d) / previous.to_d) * 100).round(1)
  end
end
