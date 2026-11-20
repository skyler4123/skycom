# frozen_string_literal: true

require "csv"

# Inventory::LedgerCsvService — the Export button's file. Exports exactly the
# current ledger search + filter (never the whole warehouse), with the same
# columns the table shows.
# Docs: docs/business_analysis/05-inventory.md §2.5
class Inventory::LedgerCsvService
  HEADERS = [ "Item", "Code", "Location", "On hand", "Reserved", "Available", "Reorder at", "Status" ].freeze

  def self.call(company:, warehouse:, q: nil, filter: "all")
    new(company: company, warehouse: warehouse, q: q, filter: filter).call
  end

  def initialize(company:, warehouse:, q: nil, filter: "all")
    @company = company
    @warehouse = warehouse
    @q = q
    @filter = filter
  end

  def call
    if ledger.filtered_count > EXPORT_MAX_RECORDS
      raise Inventory::Error, "Export exceeds the maximum of #{EXPORT_MAX_RECORDS} rows."
    end

    CSV.generate do |csv|
      csv << HEADERS
      ledger.all_stocks(limit: EXPORT_MAX_RECORDS).each do |stock|
        on_hand = stock.quantity.to_i
        reserved = stock.pending.to_i
        available = [ on_hand - reserved, 0 ].max
        reorder_point = stock.reorder_point.to_i
        csv << [
          stock.name.presence || stock.product&.name.presence || "—",
          stock.code.presence || stock.product&.code.presence || "—",
          stock.property_string_1.presence || "No location",
          on_hand,
          reserved,
          available,
          reorder_point,
          status_label(available, reorder_point)
        ]
      end
    end
  end

  def filename
    label = warehouse.code.presence || warehouse.name.to_s.parameterize.presence || "warehouse"
    "#{label}-stock-#{filter_label}.csv"
  end

  private

  attr_reader :company, :warehouse, :q, :filter

  def ledger
    @ledger ||= Inventory::LedgerQueryService.new(
      company: company,
      warehouse: warehouse,
      q: q,
      filter: filter
    )
  end

  def filter_label
    Inventory::LedgerQueryService::FILTERS.include?(filter.to_s) ? filter.to_s : "all"
  end

  def status_label(available, reorder_point)
    if available <= 0
      "Out"
    elsif available <= reorder_point
      "Low"
    else
      "In stock"
    end
  end
end
