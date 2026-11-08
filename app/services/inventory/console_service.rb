# frozen_string_literal: true

# Inventory::ConsoleService — builds the live payload for the Inventory
# operation screen. Derives vital metrics, the granular stock ledger, active
# freight docks, zone capacity and the audit summary from the stock domain
# (Stock, StockImport, StockExport, Warehouse, Product).
#
# Why it exists: the Inventory operation is the warehouse-level command screen
# for stock truth, inbound/outbound movement and capacity. Keeping the
# aggregation here lets the controller stay a thin shell.
# Docs: docs/OPERATIONS.md, docs/STOCK.md
class Inventory::ConsoleService
  STOCK_LIMIT = 200
  DOCK_LIMIT = 4
  ZONE_LIMIT = 6

  def self.call(company:, appointment:, now: Time.current)
    new(company: company, appointment: appointment, now: now).call
  end

  def initialize(company:, appointment:, now:)
    @company = company
    @appointment = appointment
    @warehouse = appointment.warehouse
    @branch = @warehouse&.branch
    @branch ||= appointment.branch if appointment.respond_to?(:branch)
    @now = now
  end

  def call
    {
      location: location_payload,
      currency: company.currency || "usd",
      metrics: metrics_payload,
      stocks: stocks_payload,
      low_stock_count: low_stock_count,
      docks: docks_payload,
      zones: zones_payload,
      global_utilization: global_utilization,
      audit: audit_payload,
      generated_at: now.iso8601
    }
  end

  private

  attr_reader :company, :appointment, :branch, :warehouse, :now

  def location_payload
    if warehouse.present?
      {
        id: warehouse.id,
        name: warehouse.name,
        code: warehouse.code,
        kind: "warehouse"
      }
    else
      {
        id: branch&.id,
        name: branch&.name,
        code: branch&.code,
        kind: "branch"
      }
    end
  end

  def scope_stocks
    @scope_stocks ||= begin
      scope = company.stocks.where(discarded_at: nil)
      if warehouse.present?
        scope = scope.where(warehouse_id: warehouse.id)
      elsif branch.present?
        scope = scope.where(branch_id: branch.id)
      end
      scope.includes(:product, :warehouse).order(:name)
    end
  end

  def total_skus
    @total_skus ||= scope_stocks.count
  end

  def low_stock_count
    @low_stock_count ||= scope_stocks.where("quantity - pending <= ?", LOW_STOCK_THRESHOLD).count
  end

  def zero_stock_count
    @zero_stock_count ||= scope_stocks.where("quantity - pending <= 0").count
  end

  def metrics_payload
    inbound = recent_imports
    outbound = recent_exports

    {
      total_skus_active: total_skus,
      total_skus_zones: warehouses_for_zones.count,
      stock_criticality: low_stock_count,
      zero_stock_outages: zero_stock_count,
      inbound_shipments: inbound.length,
      inbound_units: inbound.sum { |record| record.quantity.to_i },
      inbound_docked: inbound.count { |record| %w[received in_progress confirmed].include?(record.workflow_status.to_s) },
      outbound_dispatches: outbound.length,
      outbound_cartons: outbound.sum { |record| record.quantity.to_i },
      outbound_staged: outbound.count { |record| %w[confirmed in_progress].include?(record.workflow_status.to_s) },
      bom_shortage_work_orders: 0,
      bom_missing_parts: 0
    }
  end

  def stocks_payload
    scope_stocks.limit(STOCK_LIMIT).map do |stock|
      on_hand = stock.quantity.to_i
      allocated = stock.pending.to_i
      available = [ on_hand - allocated, 0 ].max
      status = stock_status(available)

      {
        id: stock.id,
        name: stock.name.presence || stock.product&.name.presence || "Stock item",
        code: stock.code.presence || stock.product&.code.presence || "—",
        price: stock.price&.to_f || stock.product&.price&.to_f || 0,
        currency: stock.currency.presence || company.currency || "usd",
        bin_location: stock.property_string_1.presence || stock.warehouse&.name.presence || "—",
        on_hand: on_hand,
        allocated: allocated,
        available: available,
        min_safe: LOW_STOCK_THRESHOLD,
        status: status[:key],
        status_label: status[:label],
        status_tone: status[:tone],
        stock_path: "/companies/#{company.id}/stocks/#{stock.id}"
      }
    end
  end

  def stock_status(available)
    if available <= 0
      { key: "critical", label: "Critical Stockout", tone: "danger" }
    elsif available <= LOW_STOCK_THRESHOLD / 2
      { key: "low", label: "Low Stock", tone: "danger" }
    elsif available <= LOW_STOCK_THRESHOLD
      { key: "reorder", label: "Reorder Alert", tone: "warning" }
    else
      { key: "in_stock", label: "In Stock", tone: "success" }
    end
  end

  def recent_imports
    @recent_imports ||= begin
      scope = company.stock_imports.where(discarded_at: nil).order(created_at: :desc).limit(DOCK_LIMIT)
      scope = scope.where(warehouse_id: warehouse.id) if warehouse.present?
      scope = scope.where(branch_id: branch.id) if warehouse.blank? && branch.present?
      scope.to_a
    end
  end

  def recent_exports
    @recent_exports ||= begin
      scope = company.stock_exports.where(discarded_at: nil).order(created_at: :desc).limit(DOCK_LIMIT)
      scope = scope.where(warehouse_id: warehouse.id) if warehouse.present?
      scope = scope.where(branch_id: branch.id) if warehouse.blank? && branch.present?
      scope.to_a
    end
  end

  def docks_payload
    {
      inbound: recent_imports.map { |record| inbound_dock_payload(record) },
      outbound: recent_exports.map { |record| outbound_dock_payload(record) }
    }
  end

  def inbound_dock_payload(record)
    {
      id: record.id,
      code: record.code.presence || "IMP-#{record.id.to_s.first(8).upcase}",
      gate: "Gate #{gate_number(record)}",
      supplier: party_name(record.appoint_from) || party_name(record.appoint_by) || record.name.presence || "Supplier",
      pallets: [ record.quantity.to_i / 10, 1 ].max,
      units: record.quantity.to_i,
      workflow_status: record.workflow_status,
      status_label: record.workflow_status.to_s.humanize,
      progress: dock_progress(record)
    }
  end

  def outbound_dock_payload(record)
    {
      id: record.id,
      code: record.code.presence || "EXP-#{record.id.to_s.first(8).upcase}",
      bay: "Bay #{gate_number(record)}",
      destination: party_name(record.appoint_to) || record.name.presence || "Destination",
      cartons: [ record.quantity.to_i / 5, 1 ].max,
      weight: record.quantity.to_i,
      carrier: party_name(record.appoint_by) || "Carrier",
      workflow_status: record.workflow_status,
      status_label: record.workflow_status.to_s.humanize,
      progress: dock_progress(record)
    }
  end

  def party_name(record)
    record&.respond_to?(:name) ? record.name : nil
  end

  def gate_number(record)
    (record.id.to_s.bytes.sum % 8) + 1
  end

  def dock_progress(record)
    case record.workflow_status.to_s
    when "received", "completed", "paid" then 100
    when "in_progress", "confirmed", "shipped" then 65
    when "pending" then 35
    else 15
    end
  end

  def warehouses_for_zones
    @warehouses_for_zones ||= begin
      scope = company.warehouses.where(discarded_at: nil)
      if branch.present?
        scope = scope.where(branch_id: branch.id)
      elsif warehouse.present?
        scope = scope.where(id: warehouse.id)
      end
      scope.limit(ZONE_LIMIT).to_a
    end
  end

  def zones_payload
    warehouses_for_zones.map.with_index do |zone_warehouse, index|
      stock_count = company.stocks.where(warehouse_id: zone_warehouse.id, discarded_at: nil).count
      occupancy = [ stock_count * 5, 5 ].max.clamp(5, 98)
      tone = if occupancy >= 90
        "danger"
      elsif occupancy >= 70
        "primary"
      else
        "success"
      end

      {
        id: zone_warehouse.id,
        name: "Zone #{(65 + index).chr}: #{zone_warehouse.name}",
        occupancy: occupancy,
        tone: tone,
        note: "#{stock_count} stock rows"
      }
    end
  end

  def global_utilization
    zones = zones_payload
    return 84 if zones.empty?

    (zones.sum { |zone| zone[:occupancy] }.to_f / zones.length).round(1)
  end

  # Cycle audits are not modelled yet. Report availability honestly instead of
  # inventing a clean percentage; the screen shows an empty state until an audit
  # source exists.
  def audit_payload
    {
      available: false,
      clean_pct: nil,
      last_audit_days_ago: nil,
      auditor: nil,
      discrepancies: nil,
      total_lines: total_skus
    }
  end
end
