# frozen_string_literal: true

require "rails_helper"

RSpec.describe Pos::CatalogService do
  let(:company) { create(:company, currency: :usd) }
  let(:branch) { create(:branch, company: company) }
  let(:warehouse) { create(:warehouse, company: company, branch: branch, name: "Main warehouse", business_type: :main) }
  let(:product) { create(:product, company: company, branch: branch, name: "Widget", price_cents: 5_000) }
  let(:service) do
    Seed::ServiceService.create(company: company, branch: branch, name: "Assembly").tap do |record|
      record.update!(price_cents: 2_500)
    end
  end

  before do
    category = product.category
    Stock.create!(
      company: company, warehouse: warehouse, product: product,
      quantity: 12, pending: 0, category: category,
      property_mapping: category.default_property_mapping
    ).tap { |record| record.send(:sync_available_counter) }
    service
    TaxConfig.for_company!(company).update!(pos_tax_rate_bp: 800, pos_tax_name: "Sales tax")
  end

  it "returns cents, company currency, tax, counts, and the selling warehouse" do
    result = described_class.call(company: company, branch: branch)

    expect(result[:currency]).to eq("usd")
    expect(result.dig(:tax, :rate_bp)).to eq(800)
    expect(result.dig(:tax, :name)).to eq("Sales tax")
    expect(result.dig(:catalog, :limit)).to eq(POS_CATALOG_LIMIT)
    expect(result.dig(:catalog, :products_total)).to eq(1)
    expect(result.dig(:catalog, :services_total)).to eq(1)

    product_row = result[:products].first
    expect(product_row[:price_cents]).to eq(5_000)
    expect(product_row[:price_set]).to be(true)
    expect(product_row[:stock_quantity]).to eq(12)
    expect(product_row[:stock_warehouse_name]).to eq("Main warehouse")

    service_row = result[:services].first
    expect(service_row[:price_cents]).to eq(2_500)
    expect(service_row[:price_set]).to be(true)
    expect(service_row).not_to have_key(:stock_quantity)
  end

  it "marks an unset price instead of pretending it is zero" do
    product.update_columns(price_cents: nil)

    row = described_class.call(company: company, branch: branch)[:products].first

    expect(row[:price_cents]).to be_nil
    expect(row[:price_set]).to be(false)
  end
end
