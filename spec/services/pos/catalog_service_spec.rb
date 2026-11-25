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
  let(:default_tax) { create(:tax_code, company: company, name: "Sales tax", rate_bp: 800) }

  before do
    category = product.category
    Stock.create!(
      company: company, warehouse: warehouse, product: product,
      quantity: 12, pending: 0, category: category,
      property_mapping: category.default_property_mapping
    ).tap { |record| record.send(:sync_available_counter) }
    service
    TaxConfig.for_company!(company).update!(default_tax_code_id: default_tax.id)
  end

  it "returns cents, company currency, per-item tax, counts, and the selling warehouse" do
    result = described_class.call(company: company, branch: branch)

    expect(result[:currency]).to eq("usd")
    expect(result.dig(:catalog, :limit)).to eq(POS_CATALOG_LIMIT)
    expect(result.dig(:catalog, :products_total)).to eq(1)
    expect(result.dig(:catalog, :services_total)).to eq(1)

    product_row = result[:products].first
    expect(product_row[:price_cents]).to eq(5_000)
    expect(product_row[:price_set]).to be(true)
    expect(product_row[:stock_quantity]).to eq(12)
    expect(product_row[:stock_warehouse_name]).to eq("Main warehouse")
    expect(product_row[:tax]).to include(name: "Sales tax", rate_bp: 800, inclusive: false)

    service_row = result[:services].first
    expect(service_row[:price_cents]).to eq(2_500)
    expect(service_row[:price_set]).to be(true)
    expect(service_row).not_to have_key(:stock_quantity)
    expect(service_row[:tax]).to include(name: "Sales tax", rate_bp: 800)
  end

  it "uses the item's assigned code instead of the default" do
    assigned = create(:tax_code, company: company, name: "VAT 5%", rate_bp: 500, is_inclusive: true)
    product.update!(tax_code: assigned)

    row = described_class.call(company: company, branch: branch)[:products].first

    expect(row[:tax]).to include(name: "VAT 5%", rate_bp: 500, inclusive: true)
  end

  it "returns nil tax when there is no code and no default" do
    TaxConfig.for_company!(company).update!(default_tax_code_id: nil)

    row = described_class.call(company: company, branch: branch)[:products].first

    expect(row[:tax]).to be_nil
  end

  it "marks an unset price instead of pretending it is zero" do
    product.update_columns(price_cents: nil)

    row = described_class.call(company: company, branch: branch)[:products].first

    expect(row[:price_cents]).to be_nil
    expect(row[:price_set]).to be(false)
  end
end
