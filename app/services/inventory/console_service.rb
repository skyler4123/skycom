# frozen_string_literal: true

# Inventory::ConsoleService — builds the live payload for the Inventory
# operation screen. Every number comes from the stock domain, scoped to the
# operation's warehouse: the server-paged ledger, the four KPI cards, open
# inbound/outbound records and the cycle-count state.
#
# Why it exists: the Inventory operation is the warehouse-level command screen
# for stock truth and the four loops (receive, transfer/export, adjust,
# count). Keeping the aggregation here lets the controller stay a thin shell.
# Docs: docs/OPERATIONS.md, docs/STOCK.md, docs/business_analysis/05-inventory.md
class Inventory::ConsoleService
  INBOUND_RECENT_LIMIT = 5
  OUTBOUND_RECENT_LIMIT = 5

  CLOSED_IMPORT_STATUSES = %w[received completed cancelled failed].freeze
  CLOSED_TRANSFER_STATUSES = %w[received cancelled].freeze
  CLOSED_EXPORT_STATUSES = %w[shipped completed cancelled failed].freeze

  def self.call(company:, appointment:, now: Time.current)
    new(company: company, appointment: appointment, now: now).call
  end

  def initialize(company:, appointment:, now:)
    @company = company
    @appointment = appointment
    @warehouse = appointment.warehouse
    @now = now

    raise Inventory::Error, "Inventory requires a warehouse." if @warehouse.nil?
  end

  def call
    ledger = Inventory::LedgerQueryService.call(company: company, warehouse: warehouse)

    {
      location: location_payload,
      currency: company.currency || "usd",
      generated_at: now.iso8601,
      metrics: metrics_payload(ledger),
      stocks: ledger[:stocks],
      pagination: ledger[:pagination],
      counts: ledger[:counts],
      search_capped: ledger[:search_capped],
      reorder_default: LOW_STOCK_THRESHOLD,
      reorder_rules_present: reorder_rules_present?,
      adjustment_reasons: STOCK_ADJUSTMENT_REASONS,
      inbound: inbound_payload,
      outbound: outbound_payload,
      open_count: open_count_payload,
      last_count: last_count_payload,
      reference: reference_payload
    }
  end

  private

  attr_reader :company, :appointment, :warehouse, :now

  def location_payload
    {
      id: warehouse.id,
      name: warehouse.name,
      code: warehouse.code,
      kind: "warehouse",
      timezone: warehouse.timezone,
      utc_offset: LocalTime.offset_seconds(warehouse)
    }
  end

  def metrics_payload(ledger)
    {
      stock_rows: ledger[:counts][:all],
      units_on_hand: base_stocks.sum(:quantity).to_i,
      needs_attention: ledger[:counts][:low],
      at_zero_available: ledger[:counts][:out],
      inbound_open: open_imports.size,
      inbound_units: open_imports.sum { |record| import_units(record) },
      outbound_open: open_transfers.size + open_exports.size,
      outbound_units: open_transfers.sum { |record| record.quantity.to_i } +
        open_exports.sum { |record| record.quantity.to_i }
    }
  end

  def base_stocks
    @base_stocks ||= company.stocks.where(warehouse_id: warehouse.id, discarded_at: nil)
  end

  def reorder_rules_present?
    ReorderRule.where(company_id: company.id, warehouse_id: warehouse.id, is_active: true, discarded_at: nil).exists?
  end

  # --- Inbound ---------------------------------------------------------------------

  def inbound_payload
    {
      open_imports: open_imports.map { |record| import_card(record) },
      incoming_transfers: incoming_transfers.map { |record| transfer_card(record, direction: :in) },
      recent: recent_inbound
    }
  end

  def open_imports
    @open_imports ||= import_scope
      .where.not(workflow_status: StockImport.workflow_statuses.values_at(*CLOSED_IMPORT_STATUSES))
      .order(created_at: :desc)
      .includes(:appoint_from, :stock_import_stock_appointments, purchase: :supplier)
      .to_a
  end

  def recent_imports
    @recent_imports ||= import_scope
      .where(workflow_status: StockImport.workflow_statuses.values_at("received", "completed"))
      .order(updated_at: :desc)
      .limit(INBOUND_RECENT_LIMIT)
      .includes(:appoint_from, :stock_import_stock_appointments, purchase: :supplier)
      .to_a
  end

  def import_scope
    company.stock_imports.where(warehouse_id: warehouse.id, discarded_at: nil)
  end

  def incoming_transfers
    @incoming_transfers ||= transfer_scope
      .where(destination_warehouse_id: warehouse.id, workflow_status: :initiated)
      .order(created_at: :desc)
      .includes(:warehouse, :destination_warehouse, :stock_transfer_stock_appointments)
      .to_a
  end

  def recent_inbound_transfers
    @recent_inbound_transfers ||= transfer_scope
      .where(destination_warehouse_id: warehouse.id, workflow_status: :received)
      .order(received_at: :desc)
      .limit(INBOUND_RECENT_LIMIT)
      .includes(:warehouse, :destination_warehouse, :stock_transfer_stock_appointments)
      .to_a
  end

  def recent_inbound
    entries = []
    recent_imports.each { |record| entries << [ record.received_at || record.updated_at, import_card(record) ] }
    recent_inbound_transfers.each { |record| entries << [ record.received_at || record.updated_at, transfer_card(record, direction: :in) ] }

    entries.sort_by(&:first).last(INBOUND_RECENT_LIMIT).reverse.map(&:last)
  end

  # --- Outbound --------------------------------------------------------------------

  def outbound_payload
    {
      open: open_outbound_cards,
      recent: recent_outbound
    }
  end

  def open_outbound_cards
    @open_outbound_cards ||= begin
      cards = open_transfers.map { |record| transfer_card(record, direction: :out) }
      cards += open_exports.map { |record| export_card(record) }
      cards.sort_by { |card| card[:date] }.reverse
    end
  end

  def open_transfers
    @open_transfers ||= transfer_scope
      .where(warehouse_id: warehouse.id, workflow_status: StockTransfer.workflow_statuses.values_at("draft", "pending", "initiated"))
      .order(created_at: :desc)
      .includes(:warehouse, :destination_warehouse, :stock_transfer_stock_appointments)
      .to_a
  end

  def recent_out_transfers
    @recent_out_transfers ||= transfer_scope
      .where(warehouse_id: warehouse.id, workflow_status: :received)
      .order(received_at: :desc)
      .limit(OUTBOUND_RECENT_LIMIT)
      .includes(:warehouse, :destination_warehouse, :stock_transfer_stock_appointments)
      .to_a
  end

  def open_exports
    @open_exports ||= export_scope
      .where(workflow_status: StockExport.workflow_statuses.values_at("draft", "pending", "confirmed", "in_progress"))
      .order(created_at: :desc)
      .includes(:appoint_to, :stock_export_stock_appointments)
      .to_a
  end

  def recent_shipped_exports
    @recent_shipped_exports ||= export_scope
      .where(workflow_status: StockExport.workflow_statuses.values_at("shipped", "completed"))
      .order(updated_at: :desc)
      .limit(OUTBOUND_RECENT_LIMIT)
      .includes(:appoint_to, :stock_export_stock_appointments)
      .to_a
  end

  def recent_outbound
    entries = []
    recent_out_transfers.each { |record| entries << [ record.received_at || record.updated_at, transfer_card(record, direction: :out) ] }
    recent_shipped_exports.each { |record| entries << [ record.updated_at, export_card(record) ] }

    entries.sort_by(&:first).last(OUTBOUND_RECENT_LIMIT).reverse.map(&:last)
  end

  def transfer_scope
    company.stock_transfers.where(discarded_at: nil)
  end

  def export_scope
    company.stock_exports.where(warehouse_id: warehouse.id, discarded_at: nil)
  end

  # --- Cards -----------------------------------------------------------------------

  def import_card(record)
    occurred_at = record.received_at || record.updated_at || record.created_at
    {
      id: record.id,
      kind: "import",
      code: record.code,
      party: supplier_name(record),
      date: occurred_at.iso8601,
      units: import_units(record),
      status: import_status(record),
      status_label: import_status_label(record.workflow_status),
      open: CLOSED_IMPORT_STATUSES.exclude?(record.workflow_status.to_s),
      has_lines: record.stock_import_stock_appointments.any?
    }
  end

  def transfer_card(record, direction:)
    occurred_at = record.received_at || record.updated_at || record.created_at
    party = direction == :in ? record.warehouse&.name : record.destination_warehouse&.name
    {
      id: record.id,
      kind: "transfer",
      code: record.code,
      party: party,
      date: occurred_at.iso8601,
      units: record.quantity.to_i,
      status: "transfer",
      status_label: transfer_status_label(record.workflow_status),
      open: CLOSED_TRANSFER_STATUSES.exclude?(record.workflow_status.to_s),
      direction: direction.to_s,
      destination_warehouse_id: record.destination_warehouse_id,
      source_warehouse_id: record.warehouse_id
    }
  end

  def export_card(record)
    occurred_at = record.updated_at || record.created_at
    {
      id: record.id,
      kind: "export",
      code: record.code,
      party: record.appoint_to&.try(:name).presence || record.name.presence,
      date: occurred_at.iso8601,
      units: record.quantity.to_i,
      status: "export",
      status_label: export_status_label(record.workflow_status),
      open: CLOSED_EXPORT_STATUSES.exclude?(record.workflow_status.to_s)
    }
  end

  def import_units(record)
    return record.quantity.to_i if record.quantity.to_i.positive?

    record.stock_import_stock_appointments.sum(&:quantity).to_i
  end

  def supplier_name(record)
    record.purchase&.supplier&.name.presence ||
      (record.appoint_from.is_a?(Supplier) ? record.appoint_from&.name.presence : nil) ||
      (record.appoint_by.is_a?(Supplier) ? record.appoint_by&.name.presence : nil)
  end

  def import_status(record)
    record.workflow_status.to_s
  end

  def import_status_label(status)
    case status.to_s
    when "draft", "pending" then "Draft"
    when "confirmed", "in_progress" then "Receiving"
    when "received", "completed" then "Received"
    when "cancelled" then "Cancelled"
    when "failed" then "Failed"
    else status.to_s.humanize
    end
  end

  def transfer_status_label(status)
    case status.to_s
    when "draft", "pending" then "Draft"
    when "initiated" then "In transit"
    when "received" then "Received"
    when "cancelled" then "Cancelled"
    else status.to_s.humanize
    end
  end

  def export_status_label(status)
    case status.to_s
    when "draft", "pending" then "Draft"
    when "confirmed", "in_progress" then "Processing"
    when "shipped", "completed" then "Shipped"
    when "cancelled" then "Cancelled"
    when "failed" then "Failed"
    else status.to_s.humanize
    end
  end

  # --- Cycle count -----------------------------------------------------------------

  def open_count_payload
    count = company.stock_counts.where(warehouse_id: warehouse.id).open_counts.recent_first.includes(:created_by_employee).first
    return nil if count.blank?

    count_summary(count).merge(started_at: (count.started_at || count.created_at).iso8601)
  end

  def last_count_payload
    count = company.stock_counts.where(warehouse_id: warehouse.id).completed_recent_first.includes(:created_by_employee).first
    return nil if count.blank?

    count_summary(count).merge(completed_at: (count.completed_at || count.updated_at).iso8601)
  end

  def count_summary(count)
    {
      id: count.id,
      status: count.status,
      employee_name: count.metadata&.dig("completed_by_name").presence || count.created_by_employee&.name,
      rows_counted: count.rows_counted,
      rows_total: count.rows_total,
      net_variance: count.variance_quantity,
      failed_count: Array(count.metadata&.dig("failed_lines")).size
    }
  end

  # --- Reference data --------------------------------------------------------------

  def reference_payload
    {
      suppliers: company.suppliers.where(discarded_at: nil).order(:name).map { |supplier| { id: supplier.id, name: supplier.name } },
      warehouses: company.warehouses
        .where(discarded_at: nil)
        .where.not(id: warehouse.id)
        .order(:name)
        .map { |record| { id: record.id, name: record.name, code: record.code } }
    }
  end
end
