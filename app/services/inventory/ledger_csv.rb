# frozen_string_literal: true

require "csv"

# Inventory::LedgerCsv — renders the Inventory ledger view as CSV.
#
# Why it exists: the Export CSV control must download the view the user is
# looking at (tab + search), with the same columns as the table. Rendering it
# server-side makes the file a real attachment and lets a request spec prove its
# contents.
# How it works: takes Stocks::RowPresenter hashes and writes one row per stock,
# in the same column order as the table. Money is a two-decimal major-unit
# number; the header names the currency so the file is unambiguous.
# Docs: docs/EXPORT.md, docs/OPERATIONS.md
class Inventory::LedgerCsv
  HEADERS = [ "Product", "Code", "Price", "Location", "On hand", "Reserved",
              "Available", "Minimum", "Status" ].freeze

  def self.call(rows:, currency:)
    new(rows: rows, currency: currency).call
  end

  def initialize(rows:, currency:)
    @rows = rows
    @currency = (currency.presence || "usd").to_s.upcase
  end

  def call
    CSV.generate do |csv|
      csv << headers
      rows.each { |row| csv << row_values(row) }
    end
  end

  private

  attr_reader :rows, :currency

  def headers
    HEADERS.dup.tap { |copy| copy[2] = "Price (#{currency})" }
  end

  def row_values(row)
    [
      row[:name],
      row[:code],
      format("%.2f", row[:price_cents].to_i / 100.0),
      row[:location],
      row[:on_hand],
      row[:reserved],
      row[:available],
      row[:minimum],
      row[:status_label]
    ]
  end
end
