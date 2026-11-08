# frozen_string_literal: true

require "rails_helper"

RSpec.describe StoreManager::ConsoleService do
  let(:company) { create(:company, business_type: :retail) }
  let(:branch) { create(:branch, company: company, name: "Downtown Branch") }
  let(:warehouse) { create(:warehouse, company: company, branch: branch, name: "Central Distribution Hub") }
  let(:operation) { create(:operation, company: company, branch: branch, operation_type: :store_manager) }
  let(:appointment) { branch.branch_operation_appointments.find_by!(operation: operation) }

  def create_stock(product:, quantity:, pending: 0, name:, code:)
    Stock.create!(
      company: company,
      product: product,
      warehouse: warehouse,
      quantity: quantity,
      pending: pending,
      name: name,
      code: code,
      business_type: :inventory,
      lifecycle_status: :active,
      workflow_status: :confirmed
    )
  end

  def create_import(product:, quantity:, name:)
    StockImport.create!(
      company: company,
      branch: branch,
      warehouse: warehouse,
      product: product,
      quantity: quantity,
      name: name,
      code: "STKIM-#{SecureRandom.hex(4).upcase}",
      business_type: :purchase,
      lifecycle_status: :active,
      workflow_status: :confirmed
    )
  end

  def create_export(product:, quantity:, name:)
    StockExport.create!(
      company: company,
      branch: branch,
      warehouse: warehouse,
      product: product,
      quantity: quantity,
      name: name,
      code: "STKEX-#{SecureRandom.hex(4).upcase}",
      business_type: :sale,
      lifecycle_status: :active,
      workflow_status: :confirmed
    )
  end

  it "returns the branch's stock, inbound and outbound payloads" do
    low_product = create(:product, company: company, name: "Micro-Controller PCB")
    healthy_product = create(:product, company: company, name: "Alloy Frame Chassis")

    low_stock = create_stock(product: low_product, quantity: 5, pending: 0,
      name: "Micro-Controller PCB v2.4", code: "SKU-ELEC-9021")
    healthy_stock = create_stock(product: healthy_product, quantity: 100, pending: 20,
      name: "Alloy Frame Chassis Type-A", code: "SKU-MFG-3310")

    create_import(product: low_product, quantity: 40, name: "Apex Silicon Ltd")
    create_export(product: healthy_product, quantity: 12, name: "Regional Retail Hub #04")

    payload = described_class.call(company: company, appointment: appointment)

    expect(payload.fetch(:branch)).to eq(id: branch.id, name: "Downtown Branch")
    expect(payload.fetch(:warehouses)).to eq([ { id: warehouse.id, name: "Central Distribution Hub" } ])

    stocks = payload.fetch(:stocks)
    expect(stocks.map { |stock| stock.fetch(:id) }).to contain_exactly(low_stock.id, healthy_stock.id)
    expect(stocks.find { |stock| stock.fetch(:id) == low_stock.id }).to include(
      name: "Micro-Controller PCB v2.4",
      available: 5,
      status: "low"
    )
    expect(stocks.find { |stock| stock.fetch(:id) == healthy_stock.id }).to include(
      available: 80,
      reserved: 20,
      status: "in_stock"
    )

    expect(payload.fetch(:inbound)).to include(
      include(supplier: "Apex Silicon Ltd", units: 40, status: "confirmed")
    )
    expect(payload.fetch(:outbound)).to include(
      include(destination: "Regional Retail Hub #04", units: 12, status: "confirmed")
    )

    expect(payload.fetch(:kpis)).to include(
      active_skus: 2,
      low_stock_count: 1,
      stockout_count: 0,
      inbound_shipments: 1,
      inbound_units_due: 40,
      outbound_orders: 1,
      outbound_units: 12
    )
  end

  it "returns empty collections when the branch has no warehouses" do
    empty_branch = create(:branch, company: company, name: "Empty Branch")
    empty_operation = create(:operation, company: company, branch: empty_branch, operation_type: :store_manager)
    empty_appointment = empty_branch.branch_operation_appointments.find_by!(operation: empty_operation)

    payload = described_class.call(company: company, appointment: empty_appointment)

    expect(payload.fetch(:stocks)).to eq([])
    expect(payload.fetch(:inbound)).to eq([])
    expect(payload.fetch(:outbound)).to eq([])
    expect(payload.fetch(:kpis)).to include(
      active_skus: 0,
      low_stock_count: 0,
      stockout_count: 0,
      inbound_shipments: 0,
      outbound_orders: 0
    )
  end

  it "counts a depleted stock row as a stockout" do
    product = create(:product, company: company, name: "Depleted Item")
    create_stock(product: product, quantity: 0, pending: 0, name: "Depleted Item", code: "SKU-DEP-0001")

    payload = described_class.call(company: company, appointment: appointment)

    expect(payload.fetch(:stocks).first).to include(available: 0, status: "stockout")
    expect(payload.fetch(:kpis)).to include(stockout_count: 1, low_stock_count: 0)
  end
end
