class Seed::StockLineService
  class Error < StandardError; end

  LINE_ASSOCS = {
    "StockImport" => :stock_import_stock_appointments,
    "StockExport" => :stock_export_stock_appointments,
    "StockTransfer" => :stock_transfer_stock_appointments,
    "StockAdjustment" => :stock_adjustment_stock_appointments
  }.freeze

  # Splits a header quantity into `parts` positive integers that sum back to
  # the total (remainder spread over leading parts). Callers clamp `parts`
  # to the available stock count and the total itself.
  def self.split_quantity(total, parts)
    base = total / parts
    remainder = total % parts
    Array.new(parts, base).map.with_index { |q, i| q + (i < remainder ? 1 : 0) }
  end

  # Attaches line rows to a seeded movement document WITHOUT ledger rows.
  # Seeded stock quantities were written directly by Seed::StockService, so
  # writing StockTransactions here would double-count through the hardened
  # ledger callback. Seeded show pages render lines; the ledger section stays
  # hidden until real movements run through the services.
  #
  # document: persisted StockImport/Export/Transfer/Adjustment
  # warehouse: source warehouse — every line's stock must live here
  # lines: array of [product, quantity] pairs (one row per pair)
  def self.attach!(document:, company:, warehouse:, lines:)
    assoc = LINE_ASSOCS.fetch(document.class.name) do
      raise Error, "Unsupported document #{document.class.name}"
    end

    lines.each do |product, quantity|
      stock = Stock.find_by(company: company, warehouse: warehouse, product: product)
      if stock.nil?
        raise Error, "Cannot attach line: no stock row for #{product.name} in #{warehouse.name}"
      end

      document.public_send(assoc).create!(
        company: company,
        stock: stock,
        quantity: quantity
      )
    end
    document
  end
end
