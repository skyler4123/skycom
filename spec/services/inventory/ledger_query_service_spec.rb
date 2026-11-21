# frozen_string_literal: true

require "rails_helper"

RSpec.describe Inventory::LedgerQueryService, type: :service do
  let(:company_user) { create(:user, :company_owner) }
  let(:company) { Seed::CompanyService.new(user: company_user, country: :us, business_type: :retail).tap(&:save!) }
  let(:branch) { create(:branch, company: company) }
  let(:warehouse) { Seed::WarehouseService.create(company: company, branch: branch, name: "WH-01 Central", code: "WH-01") }

  def create_stock(quantity:, pending: 0, code: "SKU-#{SecureRandom.hex(3).upcase}", name: "Item #{SecureRandom.hex(2)}", location: nil)
    record_product = create(:product, company: company, name: "Product #{SecureRandom.hex(4)}")
    stock = Seed::StockService.create(
      company: company, warehouse: warehouse, branch: branch,
      product_id: record_product.id, name: name, code: code,
      quantity: quantity, pending: pending, discarded_at: nil
    )
    stock.update!(discarded_at: nil, property_string_1: location)
    stock
  end

  before { warehouse }

  it "paginates in pages of 50 and reports from/to/total" do
    60.times { |index| create_stock(quantity: 100, code: "PAGE-#{index.to_s.rjust(3, "0")}") }

    first = described_class.call(company: company, warehouse: warehouse)
    second = described_class.call(company: company, warehouse: warehouse, page: 2)

    expect(first[:stocks].length).to eq(50)
    expect(first[:pagination]).to include(page: 1, per_page: 50, count: 60, from: 1, to: 50, pages: 2, next: 2)
    expect(second[:stocks].length).to eq(10)
    expect(second[:pagination]).to include(page: 2, from: 51, to: 60, previous: 1, next: nil)
  end

  it "filters Low, Out and In stock with matching full counts" do
    create_stock(quantity: 5, code: "LOW-1")
    create_stock(quantity: 0, code: "OUT-1")
    create_stock(quantity: 50, code: "HIGH-1")

    low = described_class.call(company: company, warehouse: warehouse, filter: "low")
    out = described_class.call(company: company, warehouse: warehouse, filter: "out")
    in_stock = described_class.call(company: company, warehouse: warehouse, filter: "in_stock")

    expect(low[:counts]).to include(all: 3, low: 2, out: 1, in_stock: 1)
    expect(low[:stocks].map { |row| row[:code] }).to contain_exactly("LOW-1", "OUT-1")
    expect(out[:stocks].map { |row| row[:code] }).to eq([ "OUT-1" ])
    expect(in_stock[:stocks].map { |row| row[:code] }).to eq([ "HIGH-1" ])
  end

  it "uses a ReorderRule when one exists" do
    stock = create_stock(quantity: 15, code: "RULE-1")
    ReorderRule.create!(
      company: company, product_id: stock.product_id, warehouse: warehouse,
      min_quantity: 14, max_quantity: 30, safety_stock: 2, lead_time_days: 3,
      auto_action: :notify_only, is_active: true
    )

    result = described_class.call(company: company, warehouse: warehouse)

    expect(result[:stocks].find { |row| row[:id] == stock.id }).to include(reorder_point: 16, status: "low")
  end

  it "finds an exact code without calling Meilisearch" do
    stock = create_stock(quantity: 7, code: "EXACT-CODE")

    expect(Stock).not_to receive(:ms_raw_search)

    result = described_class.call(company: company, warehouse: warehouse, q: "EXACT-CODE")

    expect(result[:stocks].map { |row| row[:id] }).to eq([ stock.id ])
    expect(result[:counts][:all]).to eq(1)
  end

  it "narrows text search through Meilisearch and keeps the filter" do
    low = create_stock(quantity: 2, code: "MATCH-LOW")
    create_stock(quantity: 100, code: "MATCH-HIGH")

    allow(Stock).to receive(:ms_raw_search).and_return(
      "hits" => [ { "id" => low.id } ]
    )

    result = described_class.call(company: company, warehouse: warehouse, q: "MATCH", filter: "low")

    expect(Stock).to have_received(:ms_raw_search).with(
      "MATCH",
      hash_including(filter: %(company_id = "#{company.id}" AND warehouse_id = "#{warehouse.id}"))
    )
    expect(result[:stocks].map { |row| row[:code] }).to eq([ "MATCH-LOW" ])
  end

  it "returns an empty page when nothing matches" do
    create_stock(quantity: 10, code: "ONLY-1")

    allow(Stock).to receive(:ms_raw_search).and_return("hits" => [])

    result = described_class.call(company: company, warehouse: warehouse, q: "missing")

    expect(result[:stocks]).to eq([])
    expect(result[:pagination]).to include(count: 0, from: 0, to: 0, pages: 0)
  end
end
