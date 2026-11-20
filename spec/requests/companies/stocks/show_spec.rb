# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::StocksController#show", type: :request do
  let(:company) { create(:company, business_type: :retail) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company) }
  let(:warehouse) { create(:warehouse, company: company, branch: branch) }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "stocks") }
  let(:product) { create(:product, company: company, name: "Micro-Controller PCB v2.4") }
  let!(:stock) do
    Stock.create!(company: company, warehouse: warehouse, branch: branch, product: product,
      category: category, property_mapping: category.default_property_mapping,
      name: "Micro-Controller PCB v2.4", code: "SKU-ELEC-9021", quantity: 50, pending: 5,
      price_cents: 1250, property_string_1: "A-01-03")
  end

  before do
    document = StockImport.create!(company: company, branch: branch, warehouse: warehouse,
      category: category, property_mapping: category.default_property_mapping,
      product: product, code: "IMP-SHOW-001", quantity: 12,
      workflow_status: :pending, business_type: :purchase)
    document.stock_import_stock_appointments.create!(company: company, stock: stock, quantity: 12)
    StockMovementService::Imports::CreateService.execute!(document: document, employee: nil)

    get sign_in_for_test_path(email: owner.email)
  end

  it "returns the stock row with its quantities and recent movements" do
    get company_stock_path(company, stock), as: :json

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body.dig("stock")).to include(
      "id" => stock.id, "name" => "Micro-Controller PCB v2.4", "code" => "SKU-ELEC-9021",
      "location" => "A-01-03", "on_hand" => 62, "reserved" => 5, "available" => 57,
      "minimum" => 10, "status" => "in_stock", "status_label" => "In stock",
      "warehouse_name" => warehouse.name, "branch_name" => branch.name
    )
    expect(body["ledger"].length).to eq(1)
    expect(body["ledger"].first).to include(
      "transaction_type" => "import", "transaction_type_label" => "Import",
      "quantity" => 12, "document_code" => "IMP-SHOW-001"
    )
  end

  it "does not serve another company's stock row" do
    other_company = create(:company)
    other_stock = create(:stock, company: other_company)

    get company_stock_path(other_company, other_stock), as: :json

    expect(response).to have_http_status(:forbidden)
  end
end
