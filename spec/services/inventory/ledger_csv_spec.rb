# frozen_string_literal: true

require "rails_helper"

RSpec.describe Inventory::LedgerCsv do
  it "writes the table columns, a two-decimal price, and the status word" do
    rows = [ { name: "Thermal Paste", code: "SKU-PASTE", price_cents: 1250, location: nil,
               on_hand: 3, reserved: 5, available: -2, minimum: 10, status_label: "Out" } ]
    csv = CSV.parse(described_class.call(rows: rows, currency: "usd"))

    expect(csv[0]).to eq([ "Product", "Code", "Price (USD)", "Location", "On hand",
                           "Reserved", "Available", "Minimum", "Status" ])
    expect(csv[1]).to eq([ "Thermal Paste", "SKU-PASTE", "12.50", nil, "3", "5", "-2", "10", "Out" ])
  end

  it "keeps a blank location blank instead of printing a placeholder" do
    rows = [ { name: "Copper Wire", code: "SKU-WIRE", price_cents: 0, location: nil,
               on_hand: 12, reserved: 4, available: 8, minimum: 10, status_label: "Low" } ]
    csv = CSV.parse(described_class.call(rows: rows, currency: "vnd"))

    expect(csv[0][2]).to eq("Price (VND)")
    expect(csv[1][3]).to be_nil
  end
end
