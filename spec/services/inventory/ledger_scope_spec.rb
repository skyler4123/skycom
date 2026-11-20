# frozen_string_literal: true

require "rails_helper"

RSpec.describe Inventory::LedgerScope do
  let(:company) { create(:company, business_type: :retail) }
  let(:branch) { create(:branch, company: company) }
  let(:warehouse) { create(:warehouse, company: company, branch: branch) }
  let(:other_warehouse) { create(:warehouse, company: company, branch: branch) }
  let(:operation) { create(:operation, company: company, operation_type: :inventory) }
  let(:appointment) { create(:operation_warehouse_appointment, company: company, operation: operation, warehouse: warehouse) }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "stocks") }

  def stock_row(quantity:, pending:, name:, code:, location: nil, warehouse: nil)
    product = create(:product, company: company, name: name)
    Stock.create!(company: company, warehouse: warehouse || self.warehouse, branch: branch, product: product,
      category: category, property_mapping: category.default_property_mapping,
      name: name, code: code, quantity: quantity, pending: pending, property_string_1: location)
  end

  # out=2 (0 and -2) low=2 (1 and 10) in_stock=1 (11) => all=5
  let!(:rows) do
    [
      stock_row(quantity: 0, pending: 0, name: "Zero Paste", code: "SKU-0000"),
      stock_row(quantity: 3, pending: 5, name: "Short Paste", code: "SKU-NEG1"),
      stock_row(quantity: 1, pending: 0, name: "Low Wire", code: "SKU-LOW1", location: "A-01-03"),
      stock_row(quantity: 10, pending: 0, name: "Edge Wire", code: "SKU-LOW2"),
      stock_row(quantity: 11, pending: 0, name: "Full Board", code: "SKU-FULL")
    ]
  end

  def scope(**attrs)
    described_class.new(company: company, appointment: appointment, **attrs)
  end

  it "counts four disjoint buckets that add up to all" do
    expect(scope.counts).to eq("all" => 5, "low" => 2, "out" => 2, "in_stock" => 1)
  end

  it "returns only the selected bucket" do
    expect(scope(bucket: "low").rows.map { _1[:code] }).to contain_exactly("SKU-LOW1", "SKU-LOW2")
    expect(scope(bucket: "out").total).to eq(2)
    expect(scope(bucket: "in_stock").rows.map { _1[:code] }).to eq([ "SKU-FULL" ])
  end

  it "treats an unknown bucket as all" do
    expect(scope(bucket: "nonsense").bucket).to eq("all")
    expect(scope(bucket: "nonsense").total).to eq(5)
  end

  it "never includes another warehouse's rows" do
    stock_row(quantity: 0, pending: 0, name: "Elsewhere", code: "SKU-OTHER", warehouse: other_warehouse)

    expect(scope.counts["all"]).to eq(5)
    expect(scope.rows.map { _1[:code] }).not_to include("SKU-OTHER")
  end

  it "caps the rows, keeps the true total and says it is capped" do
    capped = scope(limit: 2)

    expect(capped.rows.length).to eq(2)
    expect(capped.total).to eq(5)
    expect(capped.capped?).to be true
  end

  it "applies search before the cap, so a row outside the visible page is still found" do
    Stock.ms_clear_index!
    rows.each { |row| row.ms_index!(true) }

    narrow = scope(limit: 2, q: "SKU-FULL")
    expect(narrow.rows.map { _1[:code] }).to eq([ "SKU-FULL" ])
    expect(narrow.total).to eq(1)
    expect(narrow.counts["all"]).to eq(1)
  ensure
    Stock.ms_clear_index!
  end

  it "matches name, code, and location and stays inside the warehouse" do
    Stock.ms_clear_index!
    rows.each { |row| row.ms_index!(true) }
    stock_row(quantity: 0, pending: 0, name: "Low Wire Elsewhere", code: "SKU-OUT1",
      location: "A-01-03", warehouse: other_warehouse).ms_index!(true)

    expect(scope(q: "Low Wire").rows.map { _1[:code] }).to eq([ "SKU-LOW1" ])
    expect(scope(q: "SKU-LOW1").rows.map { _1[:code] }).to eq([ "SKU-LOW1" ])
    expect(scope(q: "A-01-03").rows.map { _1[:code] }).to eq([ "SKU-LOW1" ])
  ensure
    Stock.ms_clear_index!
  end

  it "survives search text with quotes and colons" do
    Stock.ms_clear_index!
    rows.each { |row| row.ms_index!(true) }

    expect { scope(q: 'SKU-"A":1').rows }.not_to raise_error
    expect(scope(q: 'SKU-"A":1').total).to eq(0)
  ensure
    Stock.ms_clear_index!
  end

  it "exposes the warehouse code for the export filename" do
    expect(scope.warehouse_code).to eq(warehouse.code.parameterize)
  end
end
