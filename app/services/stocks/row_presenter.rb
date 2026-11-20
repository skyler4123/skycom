# frozen_string_literal: true

# Stocks::RowPresenter — the single row shape for a stock record, shared by the
# Inventory ledger, its CSV export, and the stock-row screen.
#
# Why it exists: the ledger, the export file, and the row screen must agree on
# what "available", "minimum", and "status" mean. Those rules live in the Stock
# model (available_quantity / availability_status) and the label constant; this
# class only decides the wire shape.
# How it works: call(stock, company:) returns a hash; nil name/code/location
# stay nil so the frontend renders "—" instead of inventing a value.
# Main associations: reads stock.product for the fallbacks.
# Docs: docs/STOCK.md, docs/OPERATIONS.md
class Stocks::RowPresenter
  class << self
    def call(stock, company:)
      status = stock.availability_status

      {
        id: stock.id,
        name: stock.name.presence || stock.product&.name,
        code: stock.code.presence || stock.product&.code,
        price_cents: stock.price_cents || stock.product&.price_cents || 0,
        currency: company.currency || "usd",
        location: stock.property_string_1.presence,
        on_hand: stock.quantity.to_i,
        reserved: stock.pending.to_i,
        available: stock.available_quantity,
        minimum: LOW_STOCK_THRESHOLD,
        status: status,
        status_label: STOCK_AVAILABILITY_LABELS.fetch(status),
        stock_path: "/companies/#{company.id}/stocks/#{stock.id}"
      }
    end
  end
end
