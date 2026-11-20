# frozen_string_literal: true

# Inventory::ConsoleService — builds the live payload for the Inventory
# operation screen.
#
# Why it exists: the warehouse manager needs one page that answers "what is on
# hand, what is short, and what arrived or left recently" without any invented
# metric. Keeping the aggregation here lets the controller stay a thin shell.
# How it works: KPIs are warehouse totals from Stock scopes; the ledger view
# (bucket + search + counts + cap) comes from Inventory::LedgerScope; the two
# recent lists are the latest StockImport / StockExport rows for the same
# warehouse, and their quantities are plain sums (no carton/pallet/weight
# conversions). Cycle counts are not modelled yet, so the block reports
# available: false with the real stock-row count.
# Main associations: Stock, StockImport, StockExport, Warehouse, Branch.
# Docs: docs/OPERATIONS.md, docs/STOCK.md, docs/business_analysis/05-inventory.md
class Inventory::ConsoleService
  RECENT_LIMIT = 4

  def self.call(company:, appointment:, q: nil, bucket: "all", now: Time.current)
    new(company: company, appointment: appointment, q: q, bucket: bucket, now: now).call
  end

  def initialize(company:, appointment:, q:, bucket:, now:)
    @company = company
    @appointment = appointment
    @now = now
    @ledger = Inventory::LedgerScope.new(company: company, appointment: appointment, q: q, bucket: bucket)
  end

  def call
    {
      location: location_payload,
      branch: branch_payload,
      currency: company.currency || "usd",
      generated_at: now.iso8601,
      kpis: kpis_payload,
      ledger: ledger_payload,
      recent_inbound: recent_inbound.map { document_payload(_1) },
      recent_outbound: recent_outbound.map { document_payload(_1) },
      cycle_counts: { available: false, stock_rows: stock_rows }
    }
  end

  private

  attr_reader :company, :appointment, :ledger, :now

  def warehouse
    ledger.warehouse
  end

  def branch
    ledger.branch
  end

  def stock_rows
    @stock_rows ||= ledger.base_scope.count
  end

  def location_payload
    record = warehouse || branch

    {
      id: record&.id,
      name: record&.name,
      code: record&.code,
      kind: warehouse.present? ? "warehouse" : "branch",
      timezone: record&.timezone,
      utc_offset: LocalTime.offset_seconds(record)
    }
  end

  def branch_payload
    return if branch.blank?

    { id: branch.id, name: branch.name, code: branch.code }
  end

  def kpis_payload
    inbound = recent_inbound
    outbound = recent_outbound

    {
      stock_rows: stock_rows,
      low_or_out: ledger.base_scope.low_or_out.count,
      out: ledger.base_scope.out_of_stock.count,
      minimum: LOW_STOCK_THRESHOLD,
      recent_inbound: { count: inbound.length, units: inbound.sum { _1.quantity.to_i } },
      recent_outbound: { count: outbound.length, units: outbound.sum { _1.quantity.to_i } }
    }
  end

  def ledger_payload
    {
      bucket: ledger.bucket,
      q: ledger.query,
      limit: ledger.limit,
      total: ledger.total,
      capped: ledger.capped?,
      counts: ledger.counts,
      rows: ledger.rows
    }
  end

  def recent_inbound
    @recent_inbound ||= recent_scope(company.stock_imports).to_a
  end

  def recent_outbound
    @recent_outbound ||= recent_scope(company.stock_exports).to_a
  end

  # Same warehouse scope as the ledger, newest first, capped — so the KPI count
  # always equals the number of cards under it.
  def recent_scope(base)
    scope = base.where(discarded_at: nil)
    if warehouse.present?
      scope = scope.where(warehouse_id: warehouse.id)
    elsif branch.present?
      scope = scope.where(branch_id: branch.id)
    else
      return scope.none
    end

    scope.order(created_at: :desc, id: :desc).limit(RECENT_LIMIT)
  end

  def document_payload(record)
    {
      id: record.id,
      code: record.code.presence,
      status: record.workflow_status,
      status_label: record.workflow_status.to_s.humanize,
      quantity: record.quantity.to_i,
      occurred_at: record.created_at.iso8601
    }
  end
end
