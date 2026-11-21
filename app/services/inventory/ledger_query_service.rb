# frozen_string_literal: true

# Inventory::LedgerQueryService — the one read path for the Inventory console
# ledger: warehouse scoping, Meilisearch text search, reorder-point status
# filters, full-tab counts and page slicing.
#
# Why it exists: the console must search every stock row (not the first 200)
# and the Low/Out/In-stock tabs must count the same set their rows come from.
# Keeping the SQL threshold expression in one place is what makes that true.
# Docs: docs/STOCK.md, docs/MEILISEARCH.md, docs/business_analysis/05-inventory.md
class Inventory::LedgerQueryService
  # Page size for the console ledger (docs/business_analysis/05-inventory.md §2.4).
  PAGE_SIZE = 50
  # Meilisearch safety cap per search request. The payload flags the cap so the
  # UI never claims a hidden total.
  SEARCH_MAX_IDS = 1000
  FILTERS = %w[all low out in_stock].freeze

  # SQL conditions are literal strings with bind placeholders so Brakeman can
  # verify them; the only interpolation is the reorder-point default constant in
  # the SELECT alias below (no user input reaches SQL).
  LOW_STOCK_CONDITION = Stock.low_stock_condition_sql.freeze
  OUT_OF_STOCK_CONDITION = "(stocks.quantity - stocks.pending) <= 0".freeze
  IN_STOCK_CONDITION = Stock.in_stock_condition_sql.freeze

  def self.call(company:, warehouse:, q: nil, filter: "all", page: 1, per_page: PAGE_SIZE)
    new(company: company, warehouse: warehouse, q: q, filter: filter, page: page, per_page: per_page).call
  end

  def initialize(company:, warehouse:, q: nil, filter: "all", page: 1, per_page: PAGE_SIZE)
    @company = company
    @warehouse = warehouse
    @query = q.to_s.strip
    @filter = FILTERS.include?(filter.to_s) ? filter.to_s : "all"
    @page = page.to_i.positive? ? page.to_i : 1
    @per_page = per_page.present? ? per_page.to_i.clamp(1, PAGE_SIZE) : PAGE_SIZE
  end

  def call
    {
      stocks: serialized_rows,
      pagination: pagination_payload,
      counts: counts_payload,
      search_capped: search_capped?
    }
  end

  # All filtered rows for CSV export, in the same order as the table.
  def all_stocks(limit: EXPORT_MAX_RECORDS)
    filtered_scope
      .select("stocks.*, #{reorder_point_sql} AS reorder_point")
      .includes(:product)
      .order(Arel.sql("stocks.name ASC, stocks.created_at ASC"))
      .limit(limit)
      .to_a
  end

  def filtered_count
    @filtered_count ||= filtered_scope.count
  end

  def search_capped?
    @search_capped == true
  end

  private

  attr_reader :company, :warehouse, :query, :filter, :page, :per_page

  def scope
    @scope ||= company.stocks
      .where(warehouse_id: warehouse.id, discarded_at: nil)
      .joins(reorder_join)
  end

  def reorder_join
    Stock.reorder_point_join_sql
  end

  def reorder_point_sql
    Stock.reorder_point_expression
  end

  def filtered_scope
    @filtered_scope ||= search_scope(status_scope(scope))
  end

  def status_scope(base)
    case filter
    when "low"
      base.where(LOW_STOCK_CONDITION)
    when "out"
      base.where(OUT_OF_STOCK_CONDITION)
    when "in_stock"
      base.where(IN_STOCK_CONDITION)
    else
      base
    end
  end

  # Exact code lookups are intentionally allowed by the search rule: the DB is
  # the authority for a unique code, and it keeps barcode entry working even
  # when Meilisearch is unavailable.
  def search_scope(base)
    return base if query.blank?

    exact = base.find_by("stocks.code = ?", query)
    if exact.present?
      @exact_code_match = true
      return base.where(stocks: { id: exact.id })
    end

    ids = search_ids
    return base.none if ids.empty?

    base.where(stocks: { id: ids })
  end

  def search_ids
    result = Stock.ms_raw_search(
      query,
      filter: %(company_id = "#{company.id}" AND warehouse_id = "#{warehouse.id}"),
      attributes_to_search_on: %w[name code property_string_1],
      hits_per_page: SEARCH_MAX_IDS
    )
    ids = result.fetch("hits", []).map { |hit| hit["id"] }
    @search_capped = ids.length >= SEARCH_MAX_IDS
    ids
  end

  def pagination_payload
    total = filtered_count
    pages = total.zero? ? 0 : (total.to_f / per_page).ceil
    current_page = pages.positive? ? [ page, pages ].min : 1
    offset = (current_page - 1) * per_page

    {
      page: current_page,
      per_page: per_page,
      pages: pages,
      count: total,
      from: total.zero? ? 0 : offset + 1,
      to: total.zero? ? 0 : [ offset + per_page, total ].min,
      previous: current_page > 1 ? current_page - 1 : nil,
      next: pages.positive? && current_page < pages ? current_page + 1 : nil
    }
  end

  def counts_payload
    {
      all: scope.count,
      low: scope.where(LOW_STOCK_CONDITION).count,
      out: scope.where(OUT_OF_STOCK_CONDITION).count,
      in_stock: scope.where(IN_STOCK_CONDITION).count
    }
  end

  def serialized_rows
    rows.map { |stock| serialize_stock(stock) }
  end

  def rows
    @rows ||= begin
      offset = (pagination_payload[:page] - 1) * per_page
      filtered_scope
        .select("stocks.*, #{reorder_point_sql} AS reorder_point")
        .includes(:warehouse, product: :default_supplier)
        .order(Arel.sql("stocks.name ASC, stocks.created_at ASC"))
        .offset(offset)
        .limit(per_page)
        .to_a
    end
  end

  def serialize_stock(stock)
    on_hand = stock.quantity.to_i
    reserved = stock.pending.to_i
    available = [ on_hand - reserved, 0 ].max
    reorder_point = stock.reorder_point.to_i
    status = status_for(available, reorder_point)

    {
      id: stock.id,
      product_id: stock.product_id,
      name: stock.name.presence || stock.product&.name.presence || "—",
      code: stock.code.presence || stock.product&.code.presence || "—",
      location: stock.property_string_1.presence,
      on_hand: on_hand,
      reserved: reserved,
      available: available,
      reorder_point: reorder_point,
      status: status[:key],
      status_label: status[:label],
      receivable: stock.product.present? && !stock.product.service_based?,
      default_supplier: default_supplier_for(stock),
      open_purchase: open_purchases[stock.product_id]
    }
  end

  def default_supplier_for(stock)
    supplier = stock.product&.default_supplier
    return nil if supplier.blank?

    { id: supplier.id, name: supplier.name }
  end

  def status_for(available, reorder_point)
    if available <= 0
      { key: "out", label: "Out" }
    elsif available <= reorder_point
      { key: "low", label: "Low" }
    else
      { key: "in_stock", label: "In stock" }
    end
  end

  def open_purchases
    @open_purchases ||= begin
      product_ids = rows.map(&:product_id).compact.uniq
      return {} if product_ids.empty?

      closed_statuses = Purchase.workflow_statuses.values_at("completed", "cancelled", "failed", "refunded")
      appointments = PurchasePurchaseItemAppointment
        .joins(:purchase, :purchase_item)
        .where(purchases: {
          company_id: company.id,
          warehouse_id: warehouse.id,
          discarded_at: nil
        })
        .where.not(purchases: { workflow_status: closed_statuses })
        .where(purchase_items: { product_id: product_ids })
        .includes(:purchase, :purchase_item)
        .order(Arel.sql("purchases.created_at DESC"))

      appointments.each_with_object({}) do |appointment, map|
        product_id = appointment.purchase_item.product_id
        next unless product_ids.include?(product_id)

        map[product_id] ||= {
          id: appointment.purchase.id,
          code: appointment.purchase.code,
          path: "/companies/#{company.id}/purchases/#{appointment.purchase.id}"
        }
      end
    end
  end
end
