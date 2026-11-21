# frozen_string_literal: true

require "rails_helper"

RSpec.describe Inventory::ConsoleService, type: :service do
  let(:company_user) { create(:user, :company_owner) }
  let(:company) { Seed::CompanyService.new(user: company_user, country: :us, business_type: :retail).tap(&:save!) }
  let(:branch) { create(:branch, company: company, name: "Grocery VN", code: "WH-01") }
  let(:warehouse) { Seed::WarehouseService.create(company: company, branch: branch, name: "Branch 1 Warehouse", code: "WH-01") }
  let(:operation) { create(:operation, company: company, operation_type: :inventory) }
  let(:appointment) do
    operation
    warehouse
    operation.operation_warehouse_appointments.find_by!(warehouse: warehouse)
  end
  let(:product_one) { create(:product, company: company, name: "Product 1", code: "SKU-001") }
  let(:product_two) { create(:product, company: company, name: "Product 2", code: "SKU-002") }
  let(:product_three) { create(:product, company: company, name: "Product 3", code: "SKU-003") }
  let(:product_four) { create(:product, company: company, name: "Product 4", code: "SKU-004") }

  def create_stock(product:, quantity:, pending: 0, location: nil)
    stock = Seed::StockService.create(
      company: company,
      warehouse: warehouse,
      branch: branch,
      product_id: product.id,
      name: product.name,
      code: product.code,
      quantity: quantity,
      pending: pending,
      discarded_at: nil
    )
    stock.update!(discarded_at: nil, property_string_1: location)
    stock
  end

  before do
    appointment
  end

  it "builds the ledger, four KPI metrics and the count state from real records" do
    create_stock(product: product_one, quantity: 18, pending: 12, location: "A-01")
    create_stock(product: product_two, quantity: 5, location: "A-02")
    create_stock(product: product_three, quantity: 0, location: nil)
    create_stock(product: product_four, quantity: 50, location: "B-01")

    create(:stock_import, company: company, warehouse: warehouse, product: product_one, quantity: 25,
      workflow_status: :draft, code: "IMP-OPEN-1")
    create(:stock_import, company: company, warehouse: warehouse, product: product_one, quantity: 10,
      workflow_status: :received, code: "IMP-REC-1")
    create(:stock_export, company: company, warehouse: warehouse, product: product_two, quantity: 4,
      workflow_status: :confirmed, code: "EXP-OPEN-1")

    count = StockCount.create!(
      company: company, warehouse: warehouse, count_type: :cycle, status: :completed,
      started_at: 1.hour.ago, completed_at: 30.minutes.ago,
      metadata: { "completed_by_name" => "Warehouse Lead" }
    )
    count.stock_count_lines.create!(company: company, stock: company.stocks.find_by!(product_id: product_one.id),
      expected_quantity: 18, counted_quantity: 17, variance_quantity: -1)

    payload = described_class.call(company: company, appointment: appointment)

    expect(payload[:location]).to include(name: "Branch 1 Warehouse", code: "WH-01", kind: "warehouse")
    expect(payload[:metrics]).to include(
      stock_rows: 4,
      units_on_hand: 73,
      needs_attention: 3,
      at_zero_available: 1,
      inbound_open: 1,
      inbound_units: 25,
      outbound_open: 1,
      outbound_units: 4
    )
    expect(payload[:counts]).to include(all: 4, low: 3, out: 1, in_stock: 1)
    expect(payload[:stocks].map { |row| row[:code] }).to contain_exactly("SKU-001", "SKU-002", "SKU-003", "SKU-004")
    expect(payload[:stocks].find { |row| row[:code] == "SKU-001" }).to include(
      on_hand: 18, reserved: 12, available: 6, status: "low", location: "A-01"
    )
    expect(payload[:inbound][:open_imports].map { |card| card[:code] }).to eq([ "IMP-OPEN-1" ])
    expect(payload[:inbound][:recent].map { |card| card[:code] }).to include("IMP-REC-1")
    expect(payload[:outbound][:open].map { |card| card[:code] }).to eq([ "EXP-OPEN-1" ])
    expect(payload[:last_count]).to include(
      employee_name: "Warehouse Lead", rows_counted: 1, rows_total: 1, net_variance: -1, failed_count: 0
    )
    expect(payload).not_to include(:docks, :zones, :global_utilization, :audit)
  end

  it "removes every invented BOM, zone, dock and audit key" do
    payload = described_class.call(company: company, appointment: appointment)

    expect(payload.keys).to contain_exactly(
      :location, :currency, :generated_at, :metrics, :stocks, :pagination, :counts,
      :search_capped, :reorder_default, :reorder_rules_present, :adjustment_reasons,
      :inbound, :outbound, :open_count, :last_count, :reference
    )
    expect(payload[:metrics].keys).to contain_exactly(
      :stock_rows, :units_on_hand, :needs_attention, :at_zero_available,
      :inbound_open, :inbound_units, :outbound_open, :outbound_units
    )
  end

  it "uses a ReorderRule for the row threshold when one exists" do
    stock = create_stock(product: product_one, quantity: 15, location: "A-01")
    ReorderRule.create!(
      company: company, product: product_one, warehouse: warehouse,
      min_quantity: 14, max_quantity: 30, safety_stock: 2, lead_time_days: 3,
      auto_action: :notify_only, is_active: true
    )

    payload = described_class.call(company: company, appointment: appointment)

    expect(payload[:stocks].find { |row| row[:id] == stock.id }).to include(reorder_point: 16, status: "low")
    expect(payload[:reorder_rules_present]).to be(true)
  end

  it "falls back to the company threshold when no rule exists" do
    create_stock(product: product_one, quantity: 15, location: "A-01")

    payload = described_class.call(company: company, appointment: appointment)

    expect(payload[:stocks].first).to include(reorder_point: LOW_STOCK_THRESHOLD, status: "in_stock")
    expect(payload[:reorder_rules_present]).to be(false)
    expect(payload[:reorder_default]).to eq(LOW_STOCK_THRESHOLD)
  end

  it "reports an empty count card honestly when no count exists" do
    payload = described_class.call(company: company, appointment: appointment)

    expect(payload[:last_count]).to be_nil
    expect(payload[:open_count]).to be_nil
  end
end
