# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::Operations::InventoryController", type: :request do
  let(:company) { create(:company, business_type: :retail) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company) }
  let!(:warehouse) { create(:warehouse, company: company, branch: branch) }
  let(:operation) { create(:operation, company: company, operation_type: :inventory) }
  let!(:appointment) do
    create(:operation_warehouse_appointment, company: company, operation: operation, warehouse: warehouse)
  end
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "stocks") }
  let(:other_warehouse) { create(:warehouse, company: company, branch: branch) }

  def create_stock(code:, name:, quantity:, pending:, location: nil, price_cents: nil)
    product = create(:product, company: company, name: name)
    Stock.create!(company: company, warehouse: warehouse, branch: branch, product: product,
      category: category, property_mapping: category.default_property_mapping,
      name: name, code: code, quantity: quantity, pending: pending,
      property_string_1: location, price_cents: price_cents)
  end

  def create_document(klass, code:, quantity:, status:, hours_ago:)
    product = create(:product, company: company)
    service = klass == StockImport ? Seed::StockImportService : Seed::StockExportService
    record = service.create(company: company, branch: branch, warehouse: warehouse,
      product: product, code: code, quantity: quantity, workflow_status: status)
    record.update_columns(discarded_at: nil, created_at: hours_ago.hours.ago)
    record
  end

  before do
    create_stock(code: "SKU-ELEC-9021", name: "Micro-Controller PCB v2.4", quantity: 50, pending: 5,
      location: "A-01-03", price_cents: 1250)
    create_stock(code: "SKU-WIRE-4410", name: "Copper Wire Spool", quantity: 12, pending: 4)
    create_stock(code: "SKU-PASTE-7781", name: "Thermal Paste", quantity: 3, pending: 3, location: "B-02")

    create_document(StockImport, code: "IMP-TEST-001", quantity: 120, status: :in_progress, hours_ago: 2)
    create_document(StockImport, code: "IMP-TEST-002", quantity: 30, status: :received, hours_ago: 1)
    create_document(StockExport, code: "EXP-TEST-001", quantity: 12, status: :confirmed, hours_ago: 2)
    create_document(StockExport, code: "EXP-TEST-002", quantity: 40, status: :shipped, hours_ago: 1)

    other_product = create(:product, company: company, name: "Elsewhere")
    Stock.create!(company: company, warehouse: other_warehouse, branch: branch, product: other_product,
      category: category, property_mapping: category.default_property_mapping,
      name: "Elsewhere", code: "SKU-OTHER", quantity: 0, pending: 0)

    get sign_in_for_test_path(email: owner.email)
  end

  it "returns the console payload with KPIs, ledger counts, and no fabricated keys" do
    get inventory_company_operations_path(company, operation), params: { warehouse_id: warehouse.id }, as: :json

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["coming_soon"]).to be(false)
    expect(body.dig("inventory", "location", "code")).to eq(warehouse.code)
    expect(body.dig("inventory", "location", "utc_offset")).to eq(0)
    expect(body.dig("inventory", "branch", "name")).to eq(branch.name)
    expect(body.dig("inventory", "currency")).to eq(company.currency)
    expect(Time.iso8601(body.dig("inventory", "generated_at"))).to be_within(5.seconds).of(Time.current)
    expect(body.dig("inventory", "kpis")).to eq(
      "stock_rows" => 3, "low_or_out" => 2, "out" => 1, "minimum" => 10,
      "recent_inbound" => { "count" => 2, "units" => 150 },
      "recent_outbound" => { "count" => 2, "units" => 52 }
    )
    expect(body.dig("inventory", "ledger", "counts")).to eq(
      "all" => 3, "low" => 1, "out" => 1, "in_stock" => 1
    )
    expect(body.dig("inventory").keys).to contain_exactly(
      "location", "branch", "currency", "generated_at", "kpis", "ledger",
      "recent_inbound", "recent_outbound", "cycle_counts"
    )
  end

  it "says the list is capped when more rows match than it can load" do
    stub_const("Inventory::LedgerScope::LEDGER_LIMIT", 1)

    get inventory_company_operations_path(company, operation), params: { warehouse_id: warehouse.id }, as: :json

    ledger = JSON.parse(response.body).dig("inventory", "ledger")
    expect(ledger["rows"].length).to eq(1)
    expect(ledger["total"]).to eq(3)
    expect(ledger["capped"]).to be(true)
  end

  it "finds a row outside the visible page by search" do
    stub_const("Inventory::LedgerScope::LEDGER_LIMIT", 1)
    Stock.ms_clear_index!
    Stock.find_each { _1.ms_index!(true) }

    get inventory_company_operations_path(company, operation),
      params: { warehouse_id: warehouse.id, q: "SKU-PASTE-7781" }, as: :json

    rows = JSON.parse(response.body).dig("inventory", "ledger", "rows")
    expect(rows.map { _1["code"] }).to eq([ "SKU-PASTE-7781" ])
  ensure
    Stock.ms_clear_index!
  end

  it "accepts search text with quotes and colons" do
    get inventory_company_operations_path(company, operation),
      params: { warehouse_id: warehouse.id, q: 'SKU-"A":1' }, as: :json

    expect(response).to have_http_status(:ok)
  end

  it "rejects an inactive appointment" do
    appointment.update!(workflow_status: :inactive)

    get inventory_company_operations_path(company, operation), params: { warehouse_id: warehouse.id }, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(JSON.parse(response.body)["errors"]).to include("This operation is inactive.")
  end

  it "returns not found for a non-inventory operation" do
    pos = create(:operation, company: company, branch: branch, operation_type: :pos)

    get inventory_company_operations_path(company, pos), params: { warehouse_id: warehouse.id }, as: :json

    expect(response).to have_http_status(:not_found)
  end

  it "does not serve another company's operation" do
    other_company = create(:company)
    other_operation = create(:operation, company: other_company, operation_type: :inventory)

    get inventory_company_operations_path(other_company, other_operation), as: :json

    expect(response).to have_http_status(:forbidden)
  end

  it "exports only the selected bucket, with the warehouse code in the filename" do
    get inventory_ledger_company_operations_path(company, operation),
      params: { warehouse_id: warehouse.id, bucket: "low" }

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/csv")
    expect(response.headers["Content-Disposition"]).to include(
      "inventory-#{warehouse.code.parameterize}-low-#{LocalTime.today(warehouse)}.csv"
    )
    rows = CSV.parse(response.body)
    expect(rows[0]).to eq([ "Product", "Code", "Price (#{company.currency.upcase})", "Location", "On hand",
                            "Reserved", "Available", "Minimum", "Status" ])
    expect(rows.drop(1).map { _1[1] }).to eq([ "SKU-WIRE-4410" ])
  end

  it "exports every matching row even when the screen is capped" do
    stub_const("Inventory::LedgerScope::LEDGER_LIMIT", 1)

    get inventory_ledger_company_operations_path(company, operation), params: { warehouse_id: warehouse.id }

    expect(CSV.parse(response.body).length).to eq(4) # header + 3 rows
  end

  it "refuses an export above EXPORT_MAX_RECORDS" do
    stub_const("EXPORT_MAX_RECORDS", 1)

    get inventory_ledger_company_operations_path(company, operation), params: { warehouse_id: warehouse.id }

    expect(response).to have_http_status(:unprocessable_content)
    expect(JSON.parse(response.body)["errors"].first).to include("Export exceeds maximum")
  end
end
