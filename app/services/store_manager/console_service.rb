# frozen_string_literal: true

# StoreManager::ConsoleService — builds the live Store Manager payload for a
# branch appointment:
#
# - stocks: the branch's warehouse SKU rows with hot-counter availability,
#   reserved quantity and a derived health status (in_stock / low / stockout)
# - inbound: recent StockImport documents for those warehouses
# - outbound: recent StockExport documents for those warehouses
# - kpis: the header counts derived from the same relations
#
# Why this domain: Store Manager is a read-first console over the existing
# inventory documents (StockImport/StockExport). It does not add new tables.
# Docs: docs/OPERATIONS.md, docs/STOCK.md
class StoreManager::ConsoleService
  LOW_STOCK_THRESHOLD = 10
  LIST_LIMIT = 10
  STOCK_LIMIT = 50

  def self.call(company:, appointment:)
    new(company: company, appointment: appointment).call
  end

  def initialize(company:, appointment:)
    @company = company
    @appointment = appointment
    @branch = appointment.branch
  end

  def call
    {
      branch: { id: branch.id, name: branch.name },
      warehouses: warehouses.map { |warehouse| { id: warehouse.id, name: warehouse.name } },
      kpis: kpis,
      stocks: stocks.map { |stock| stock_payload(stock) },
      inbound: inbound.map { |stock_import| inbound_payload(stock_import) },
      outbound: outbound.map { |stock_export| outbound_payload(stock_export) }
    }
  end

  private

  attr_reader :company, :appointment, :branch

  def warehouses
    @warehouses ||= branch.warehouses.order(:name).to_a
  end

  def warehouse_ids
    @warehouse_ids ||= warehouses.map(&:id)
  end

  def stocks
    @stocks ||= stocks_relation
      .includes(:product, :warehouse, :category)
      .order(:name)
      .limit(STOCK_LIMIT)
      .to_a
  end

  def stocks_relation
    @stocks_relation ||= company.stocks
      .where(warehouse_id: warehouse_ids)
      .where(discarded_at: nil)
  end

  def inbound_relation
    @inbound_relation ||= company.stock_imports
      .where(warehouse_id: warehouse_ids)
      .where(discarded_at: nil)
      .where.not(workflow_status: %i[completed cancelled])
  end

  def outbound_relation
    @outbound_relation ||= company.stock_exports
      .where(warehouse_id: warehouse_ids)
      .where(discarded_at: nil)
      .where.not(workflow_status: %i[completed cancelled])
  end

  def inbound
    @inbound ||= inbound_relation
      .includes(:product)
      .order(created_at: :desc)
      .limit(LIST_LIMIT)
      .to_a
  end

  def outbound
    @outbound ||= outbound_relation
      .includes(:product)
      .order(created_at: :desc)
      .limit(LIST_LIMIT)
      .to_a
  end

  def kpis
    @kpis ||= begin
      {
        active_skus: stocks_relation.count,
        low_stock_count: stocks_relation
          .where("quantity - pending > 0 AND quantity - pending <= ?", LOW_STOCK_THRESHOLD)
          .count,
        stockout_count: stocks_relation.where("quantity - pending <= 0").count,
        inbound_shipments: inbound_relation.count,
        inbound_units_due: inbound_relation.sum(:quantity).to_i,
        outbound_orders: outbound_relation.count,
        outbound_units: outbound_relation.sum(:quantity).to_i
      }
    end
  end

  def stock_payload(stock)
    available = available_for(stock)

    {
      id: stock.id,
      name: stock.name.presence || stock.product&.name,
      code: stock.code,
      category_name: stock.category&.name,
      business_type: stock.business_type,
      warehouse_name: stock.warehouse&.name,
      bin: stock.property_string_1,
      available: available,
      reserved: stock.pending.to_i,
      unit_cost: stock.price&.to_f || 0,
      currency: stock.currency,
      status: stock_status(available)
    }
  end

  def available_for(stock)
    [ stock.available_count.to_i, 0 ].max
  end

  def stock_status(available)
    return "stockout" if available <= 0
    return "low" if available <= LOW_STOCK_THRESHOLD

    "in_stock"
  end

  def inbound_payload(stock_import)
    {
      id: stock_import.id,
      code: stock_import.code,
      supplier: stock_import.appoint_from.try(:name).presence || stock_import.name,
      units: stock_import.quantity.to_i,
      status: stock_import.workflow_status,
      business_type: stock_import.business_type,
      created_at: stock_import.created_at&.iso8601
    }
  end

  def outbound_payload(stock_export)
    {
      id: stock_export.id,
      code: stock_export.code,
      destination: stock_export.appoint_to.try(:name).presence || stock_export.name,
      units: stock_export.quantity.to_i,
      status: stock_export.workflow_status,
      business_type: stock_export.business_type,
      created_at: stock_export.created_at&.iso8601
    }
  end
end
