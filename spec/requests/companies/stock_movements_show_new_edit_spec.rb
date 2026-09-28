# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Stock movement show/new/edit JSON", type: :request do
  let(:company) { create(:company) }
  let(:warehouse) { create(:warehouse, company: company) }
  let(:product) { create(:product, company: company, name: "Widget #{SecureRandom.hex(4)}") }
  let!(:stock) do
    Stock.create!(company: company, warehouse: warehouse, product: product,
      quantity: 50, pending: 5, name: "Spec Stock", code: "STK-SPEC-#{SecureRandom.hex(3).upcase}")
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  before { get sign_in_for_test_path(email: company.user.email) }

  it "GET stock_imports/new.json returns warehouses and stocks with DB availability" do
    get "/companies/#{company.id}/stock_imports/new.json"
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["warehouses"]).to include(hash_including("id" => warehouse.id))
    row = body["stocks"].find { |s| s["id"] == stock.id }
    expect(row["available"]).to eq(45)
    expect(row["product_name"]).to eq(product.name)
  end

  it "GET stock_imports/:id.json returns lines and ledger" do
    import = create(:stock_import, company: company, warehouse: warehouse)
    import.stock_import_stock_appointments.create!(company: company, stock: stock, quantity: 10)
    get "/companies/#{company.id}/stock_imports/#{import.id}.json"
    expect(response).to have_http_status(:ok)
    doc = JSON.parse(response.body)["stock_import"]
    expect(doc["lines"].first).to include("stock_id" => stock.id, "quantity" => 10, "product_name" => product.name)
    expect(doc["ledger"]).to be_an(Array)
  end

  it "GET stock_transfers/:id/edit.json returns document plus reference data" do
    dest = create(:warehouse, company: company)
    transfer = create(:stock_transfer, company: company, warehouse: warehouse, destination_warehouse: dest)
    get "/companies/#{company.id}/stock_transfers/#{transfer.id}/edit.json"
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["stock_transfer"]["id"]).to eq(transfer.id)
    expect(body["warehouses"].map { |w| w["id"] }).to include(warehouse.id, dest.id)
  end

  it "PATCH stock_transfers/:id rejects a stock from another warehouse" do
    other_warehouse = create(:warehouse, company: company)
    other_stock = Stock.create!(company: company, warehouse: other_warehouse, product: product,
      quantity: 10, name: "Other Stock", code: "STK-OTH-#{SecureRandom.hex(3).upcase}")
    dest = create(:warehouse, company: company)
    transfer = create(:stock_transfer, company: company, warehouse: warehouse, destination_warehouse: dest)
    transfer.update!(workflow_status: :pending)
    patch "/companies/#{company.id}/stock_transfers/#{transfer.id}.json",
      params: { stock_transfer: { name: "Renamed" }, stock_items: [ { stock_id: other_stock.id, quantity: 2 } ] }
    expect(response).to have_http_status(:unprocessable_content)
    expect(JSON.parse(response.body)["errors"].first).to match(/another warehouse/)
  end

  it "POST stock_imports with zero quantity 422s with errors and persists nothing (never 500)" do
    post "/companies/#{company.id}/stock_imports.json",
      params: { stock_import: { warehouse_id: warehouse.id, name: "Bad import" },
                stock_items: [ { stock_id: stock.id, quantity: 0 } ] }
    expect(response).to have_http_status(:unprocessable_content)
    expect(JSON.parse(response.body)["errors"]).to be_present
    expect(StockImport.where(company: company).count).to eq(0)
  end

  it "PATCH stock_transfers/:id preserves original lines when replacement items are invalid" do
    other_warehouse = create(:warehouse, company: company)
    other_stock = Stock.create!(company: company, warehouse: other_warehouse, product: product,
      quantity: 10, name: "Other Stock", code: "STK-OTH2-#{SecureRandom.hex(3).upcase}")
    dest = create(:warehouse, company: company)
    transfer = create(:stock_transfer, company: company, warehouse: warehouse, destination_warehouse: dest)
    transfer.update!(workflow_status: :pending)
    transfer.stock_transfer_stock_appointments.create!(company: company, stock: stock, quantity: 3)
    patch "/companies/#{company.id}/stock_transfers/#{transfer.id}.json",
      params: { stock_transfer: { name: "Renamed" }, stock_items: [ { stock_id: other_stock.id, quantity: 2 } ] }
    expect(response).to have_http_status(:unprocessable_content)
    surviving = transfer.reload.stock_transfer_stock_appointments
    expect(surviving.size).to eq(1)
    expect(surviving.first.stock_id).to eq(stock.id)
    expect(surviving.first.quantity).to eq(3)
  end

  it "POST stock_imports persists category and dynamic property" do
    category = Seed::CategoryService.find_or_create_for(company: company, resource_name: "stock_imports")
    post "/companies/#{company.id}/stock_imports.json",
      params: { stock_import: { warehouse_id: warehouse.id, name: "Labeled", category_id: category.id,
                                property_string_1: "Fragile" },
                stock_items: [ { stock_id: stock.id, quantity: 2 } ] }
    expect(response).to have_http_status(:ok)
    import = StockImport.find(JSON.parse(response.body)["stock_import"]["id"])
    expect(import.category_id).to eq(category.id)
    expect(import.property_string_1).to eq("Fragile")
  end

  it "PATCH stock_transfers/:id refuses an already-initiated transfer" do
    dest = create(:warehouse, company: company)
    transfer = create(:stock_transfer, company: company, warehouse: warehouse, destination_warehouse: dest)
    transfer.update!(workflow_status: :initiated)
    patch "/companies/#{company.id}/stock_transfers/#{transfer.id}.json",
      params: { stock_transfer: { name: "Renamed" } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(JSON.parse(response.body)["errors"].first).to match(/initiated/)
  end

  it "POST stock_imports with blank quantity 422s and persists nothing (never 500)" do
    post "/companies/#{company.id}/stock_imports.json",
      params: { stock_import: { warehouse_id: warehouse.id, name: "Blank qty" },
                stock_items: [ { stock_id: stock.id, quantity: "" } ] }
    expect(response).to have_http_status(:unprocessable_content)
    expect(JSON.parse(response.body)["errors"]).to be_present
    expect(StockImport.where(company: company).count).to eq(0)
  end
end
