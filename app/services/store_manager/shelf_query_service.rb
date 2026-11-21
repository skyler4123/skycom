# frozen_string_literal: true

# StoreManager::ShelfQueryService — the low-shelf table for one branch day.
#
# Today reads live Stock rows and the per-product/warehouse ReorderRule. A past
# day reads the snapshot stored by ShiftCloseService, because stock history
# cannot be reconstructed from transient pending holds. Every row carries the
# open transfer/purchase document so the next press opens that same record.
#
# Docs: docs/STOCK.md, docs/business_analysis/06-store-manager.md
class StoreManager::ShelfQueryService
  Document = Struct.new(:type, :code, :path, keyword_init: true)
  CLOSED_PURCHASE_STATUSES = %w[completed cancelled failed refunded].freeze
  OPEN_TRANSFER_STATUSES = %w[pending initiated].freeze

  def self.call(company:, branch:, date:, now: Time.current, shift_close: nil)
    new(company: company, branch: branch, date: date, now: now, shift_close: shift_close).call
  end

  def initialize(company:, branch:, date:, now:, shift_close: nil)
    @company = company
    @branch = branch
    @date = date.to_date
    @now = now
    @shift_close = shift_close
  end

  def call
    if today?
      live_payload
    elsif shift_close.present?
      snapshot_payload
    else
      empty_payload(snapshot_missing: true)
    end
  end

  private

  attr_reader :company, :branch, :date, :now, :shift_close

  def today?
    @today ||= LocalTime.today(branch, at: now) == date
  end

  def live_payload
    rows = low_stocks.map { |stock| serialize_stock(stock) }
    {
      rows: rows,
      count: rows.length,
      default_minimum: LOW_STOCK_THRESHOLD,
      reorder_rules_present: rows.any? { |row| row[:default_minimum] },
      snapshot_missing: false
    }
  end

  def snapshot_payload
    rows = Array(shift_close.shelf_snapshot).map { |row| row.deep_symbolize_keys.merge(read_only: true) }
    {
      rows: rows,
      count: rows.length,
      default_minimum: LOW_STOCK_THRESHOLD,
      reorder_rules_present: rows.any? { |row| row[:default_minimum] },
      snapshot_missing: false
    }
  end

  def empty_payload(snapshot_missing:)
    {
      rows: [],
      count: 0,
      default_minimum: LOW_STOCK_THRESHOLD,
      reorder_rules_present: false,
      snapshot_missing: snapshot_missing
    }
  end

  def low_stocks
    @low_stocks ||= company.stocks
      .joins(:warehouse)
      .joins(Stock.reorder_point_join_sql)
      .where("stocks.branch_id = :branch_id OR warehouses.branch_id = :branch_id", branch_id: branch.id)
      .where(stocks: { discarded_at: nil })
      .where(Stock.low_stock_condition_sql)
      .select("stocks.*, #{Stock.reorder_point_expression} AS reorder_point")
      .includes(:warehouse, product: :default_supplier)
      .order(Arel.sql("(stocks.quantity - stocks.pending) ASC, stocks.name ASC, stocks.created_at ASC"))
      .to_a
  end

  def reorder_rules
    @reorder_rules ||= begin
      product_ids = low_stocks.map(&:product_id).uniq
      warehouse_ids = low_stocks.map(&:warehouse_id).uniq
      return {} if product_ids.empty? || warehouse_ids.empty?

      ReorderRule.where(
        company_id: company.id,
        product_id: product_ids,
        warehouse_id: warehouse_ids,
        is_active: true,
        discarded_at: nil
      ).index_by { |rule| [ rule.product_id, rule.warehouse_id ] }
    end
  end

  def all_product_stocks
    @all_product_stocks ||= begin
      product_ids = low_stocks.map(&:product_id).uniq
      return [] if product_ids.empty?

      company.stocks
        .where(product_id: product_ids, discarded_at: nil)
        .includes(:warehouse)
        .to_a
    end
  end

  def transfers
    @transfers ||= begin
      product_ids = low_stocks.map(&:product_id).uniq
      warehouse_ids = low_stocks.map(&:warehouse_id).uniq
      return {} if product_ids.empty? || warehouse_ids.empty?

      company.stock_transfers
        .where(product_id: product_ids, destination_warehouse_id: warehouse_ids, discarded_at: nil)
        .where(workflow_status: OPEN_TRANSFER_STATUSES)
        .order(created_at: :desc)
        .index_by { |transfer| [ transfer.product_id, transfer.destination_warehouse_id ] }
    end
  end

  def purchases
    @purchases ||= begin
      product_ids = low_stocks.map(&:product_id).uniq
      warehouse_ids = low_stocks.map(&:warehouse_id).uniq
      return {} if product_ids.empty? || warehouse_ids.empty?

      appointments = PurchasePurchaseItemAppointment
        .joins(:purchase, :purchase_item)
        .where(purchases: {
          company_id: company.id,
          warehouse_id: warehouse_ids,
          discarded_at: nil
        })
        .where.not(purchases: { workflow_status: CLOSED_PURCHASE_STATUSES })
        .where(purchase_items: { product_id: product_ids })
        .includes(:purchase, :purchase_item)
        .order(Arel.sql("purchases.created_at DESC"))

      appointments.each_with_object({}) do |appointment, map|
        key = [ appointment.purchase_item.product_id, appointment.purchase.warehouse_id ]
        map[key] ||= appointment.purchase
      end
    end
  end

  def serialize_stock(stock)
    available = [ stock.quantity.to_i - stock.pending.to_i, 0 ].max
    other_stocks = all_product_stocks.select do |candidate|
      candidate.product_id == stock.product_id && candidate.warehouse_id != stock.warehouse_id
    end
    source = other_stocks.max_by { |candidate| [ candidate.quantity.to_i - candidate.pending.to_i, 0 ].max }
    warehouse_available = other_stocks.sum { |candidate| [ candidate.quantity.to_i - candidate.pending.to_i, 0 ].max }
    source_available = source ? [ source.quantity.to_i - source.pending.to_i, 0 ].max : 0
    document = documents_for(stock)
    stage = stage_for(stock, document, source_available)

    {
      stock_id: stock.id,
      product_name: stock.name.presence || stock.product&.name.presence || "Stock item",
      sku: stock.code.presence || stock.product&.code.presence || "—",
      bay: stock.property_integer_3.presence,
      shelf_quantity: available,
      on_hand: stock.quantity.to_i,
      pending: stock.pending.to_i,
      threshold: stock.reorder_point.to_i,
      default_minimum: !reorder_rules.key?([ stock.product_id, stock.warehouse_id ]),
      default_supplier: default_supplier_for(stock),
      warehouse_available: warehouse_available,
      warehouse_name: stock.warehouse&.name.presence || "Branch warehouse",
      source_warehouse_name: source&.warehouse&.name,
      source_available: source_available,
      stage_key: stage[:key],
      stage_label: stage[:label],
      stage_icon: stage[:icon],
      document_type: document&.type,
      document_code: document&.code,
      document_path: document&.path,
      action_key: stage[:action_key],
      action_label: stage[:action_label],
      stock_path: "/companies/#{company.id}/stocks/#{stock.id}"
    }
  end

  def documents_for(stock)
    transfer = transfers[[ stock.product_id, stock.warehouse_id ]]
    if transfer.present?
      return Document.new(
        type: "transfer",
        code: transfer.code,
        path: "/companies/#{company.id}/stock_transfers/#{transfer.id}"
      )
    end

    purchase = purchases[[ stock.product_id, stock.warehouse_id ]]
    return nil if purchase.blank?

    Document.new(
      type: "purchase",
      code: purchase.code,
      path: "/companies/#{company.id}/purchases/#{purchase.id}"
    )
  end

  def default_supplier_for(stock)
    supplier = stock.product&.default_supplier
    return nil if supplier.blank?

    { id: supplier.id, name: supplier.name }
  end

  def stage_for(stock, document, source_available)
    if document.present?
      {
        key: document.type,
        label: "#{document.type == 'transfer' ? 'Transfer' : 'Purchase'} #{document.code}",
        icon: document.type == "transfer" ? "swap_horiz" : "shopping_cart",
        action_key: "open",
        action_label: document.type == "transfer" ? "Open transfer" : "Open purchase"
      }
    elsif source_available.positive?
      {
        key: "not_requested",
        label: "Not requested",
        icon: "pending_actions",
        action_key: "transfer",
        action_label: "Request transfer"
      }
    else
      {
        key: "not_requested",
        label: "Not requested",
        icon: "pending_actions",
        action_key: "purchase",
        action_label: "Create purchase"
      }
    end
  end
end
