# frozen_string_literal: true

require "rails_helper"

RSpec.describe Stocks::RowPresenter do
  let(:company) { create(:company, business_type: :retail) }
  let(:warehouse) { create(:warehouse, company: company) }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "stocks") }
  let(:product) { create(:product, company: company, name: "Thermal Paste", price_cents: 900) }

  def stock(**attrs)
    Stock.create!({ company: company, warehouse: warehouse, product: product, category: category,
      property_mapping: category.default_property_mapping, name: "Thermal Paste", code: "SKU-PASTE",
      quantity: 0, pending: 0 }.merge(attrs))
  end

  it "renders the row from the record, with a blank location kept blank" do
    row = described_class.call(stock(quantity: 3, pending: 5), company: company)

    expect(row).to include(
      name: "Thermal Paste", code: "SKU-PASTE", location: nil,
      on_hand: 3, reserved: 5, available: -2, minimum: LOW_STOCK_THRESHOLD,
      status: "out", status_label: "Out"
    )
    expect(row[:stock_path]).to eq("/companies/#{company.id}/stocks/#{row[:id]}")
  end

  it "falls back to the product price and the company currency" do
    row = described_class.call(stock, company: company)

    expect(row[:price_cents]).to eq(900)
    expect(row[:currency]).to eq(company.currency)
  end

  it "prefers the stock price when present" do
    row = described_class.call(stock(price_cents: 1250), company: company)

    expect(row[:price_cents]).to eq(1250)
  end

  it "renders zero, never NaN, when neither the stock nor the product has a price" do
    product.update!(price_cents: nil)
    row = described_class.call(stock(price_cents: nil), company: company)

    expect(row[:price_cents]).to eq(0)
    expect(row[:currency]).to eq(company.currency)
  end
end
