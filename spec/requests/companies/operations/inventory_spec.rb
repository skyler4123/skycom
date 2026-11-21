# frozen_string_literal: true

require "rails_helper"
require "csv"

RSpec.describe "Companies::Operations::InventoryController", type: :request do
  let(:company) { create(:company, business_type: :retail) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company, name: "Grocery VN") }
  let!(:operation) { Seed::OperationService.create(company: company, operation_type: :inventory) }
  let!(:warehouse) { create(:warehouse, company: company, branch: branch, name: "Branch 1 Warehouse", code: "WH-01") }
  let(:appointment) { operation.operation_warehouse_appointments.find_by!(warehouse: warehouse) }
  let(:product) { create(:product, company: company, name: "Rice 5kg", code: "SKU-RICE", business_type: :physical) }

  def create_stock(quantity: 20, pending: 0, record_product: product)
    stock = Seed::StockService.create(
      company: company, warehouse: warehouse, branch: branch,
      product_id: record_product.id, name: record_product.name, code: record_product.code,
      quantity: quantity, pending: pending, discarded_at: nil
    )
    stock.update!(discarded_at: nil, property_string_1: "A-01")
    stock
  end

  before do
    appointment
    get sign_in_for_test_path(email: owner.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET #show" do
    it "returns the live console payload with no invented keys" do
      create_stock(quantity: 18, pending: 12)

      get inventory_company_operations_path(company, operation), params: { warehouse_id: warehouse.id }, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["coming_soon"]).to be(false)
      expect(body.dig("inventory", "location", "name")).to eq("Branch 1 Warehouse")
      expect(body.dig("inventory", "location", "code")).to eq("WH-01")
      expect(body.dig("inventory", "metrics", "stock_rows")).to eq(1)
      expect(body.dig("inventory", "metrics", "units_on_hand")).to eq(18)
      expect(body.dig("inventory", "stocks", 0)).to include(
        "on_hand" => 18, "reserved" => 12, "available" => 6, "status" => "low"
      )
      expect(body.dig("inventory", "stocks", 0)["location"]).to eq("A-01")
      expect(body.dig("inventory")).not_to have_key("docks")
      expect(body.dig("inventory")).not_to have_key("zones")
      expect(body.dig("inventory")).not_to have_key("global_utilization")
      expect(body.dig("inventory")).not_to have_key("audit")
      expect(body.dig("inventory", "metrics")).not_to have_key("bom_shortage_work_orders")
    end

    it "returns 403 for an operation from another company" do
      other_company = create(:company)
      other_operation = Seed::OperationService.create(company: other_company, operation_type: :inventory)

      get inventory_company_operations_path(other_company, other_operation), params: { warehouse_id: warehouse.id }, as: :json

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)["errors"]).to include("You are not authorized to perform this action.")
    end

    it "returns 422 for an inactive appointment" do
      appointment.update!(workflow_status: :inactive)

      get inventory_company_operations_path(company, operation), params: { warehouse_id: warehouse.id }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to include("This operation is inactive.")
    end
  end

  describe "GET #ledger" do
    it "filters and paginates on the server" do
      create_stock(quantity: 2)
      create_stock(quantity: 50, record_product: create(:product, company: company, name: "Coffee", business_type: :physical))

      get inventory_ledger_company_operations_path(company, operation), params: { warehouse_id: warehouse.id, filter: "low" }, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["stocks"].length).to eq(1)
      expect(body["counts"]).to include("all" => 2, "low" => 1, "in_stock" => 1)
      expect(body["pagination"]).to include("count" => 1, "from" => 1, "to" => 1)
    end
  end

  describe "GET #export" do
    it "exports only the current filter with the table columns" do
      create_stock(quantity: 2)
      create_stock(quantity: 50, record_product: create(:product, company: company, name: "Coffee", business_type: :physical))

      get inventory_export_company_operations_path(company, operation), params: { warehouse_id: warehouse.id, filter: "low" }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Disposition"]).to include("WH-01-stock-low.csv")
      rows = CSV.parse(response.body, headers: true)
      expect(rows.headers).to eq([ "Item", "Code", "Location", "On hand", "Reserved", "Available", "Reorder at", "Status" ])
      expect(rows.length).to eq(1)
      expect(rows.first["Code"]).to eq("SKU-RICE")
      expect(rows.first["Available"]).to eq("2")
      expect(rows.first["Status"]).to eq("Low")
    end
  end

  describe "POST #create_receipt" do
    it "increases on hand and returns the exact change" do
      stock = create_stock(quantity: 10)

      post inventory_receipts_company_operations_path(company, operation), params: {
        warehouse_id: warehouse.id,
        receipt: { stock_id: stock.id, quantity: 10, location: "B-02" }
      }, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["message"]).to include("Received 10", "on hand 10 → 20")
      expect(stock.reload.quantity).to eq(20)
    end

    it "returns the error contract and changes nothing for a service item" do
      service_product = create(:product, company: company, name: "Install", business_type: :service_based)
      stock = create_stock(quantity: 1, record_product: service_product)

      post inventory_receipts_company_operations_path(company, operation), params: {
        warehouse_id: warehouse.id,
        receipt: { stock_id: stock.id, quantity: 1 }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to include("Service items cannot be stocked.")
      expect(stock.reload.quantity).to eq(1)
    end
  end

  describe "POST #create_transfer and #receive_transfer" do
    it "moves stock through the two-phase flow" do
      destination = create(:warehouse, company: company, branch: branch, name: "Branch 2 Warehouse")
      stock = create_stock(quantity: 20)

      post inventory_transfers_company_operations_path(company, operation), params: {
        warehouse_id: warehouse.id,
        transfer: { stock_id: stock.id, quantity: 4, destination_warehouse_id: destination.id }
      }, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      transfer = StockTransfer.find(body["transfer_id"])
      expect(stock.reload.pending).to eq(4)
      expect(transfer.workflow_status).to eq("initiated")

      post inventory_transfer_receive_company_operations_path(company, operation, transfer.id), params: {
        warehouse_id: destination.id
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(stock.reload.quantity).to eq(16)
      expect(company.stocks.find_by!(warehouse: destination, product_id: product.id).quantity).to eq(4)
    end

    it "rejects a quantity above available" do
      destination = create(:warehouse, company: company, branch: branch, name: "Branch 2 Warehouse")
      stock = create_stock(quantity: 2)

      post inventory_transfers_company_operations_path(company, operation), params: {
        warehouse_id: warehouse.id,
        transfer: { stock_id: stock.id, quantity: 3, destination_warehouse_id: destination.id }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to include("Only 2 available in Branch 1 Warehouse.")
      expect(company.stock_transfers.count).to eq(0)
    end
  end

  describe "POST #create_export" do
    it "drops source on hand and creates nothing at a destination" do
      stock = create_stock(quantity: 10)

      post inventory_exports_company_operations_path(company, operation), params: {
        warehouse_id: warehouse.id,
        stock_export: { stock_id: stock.id, quantity: 3, reference: "Donation" }
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(stock.reload.quantity).to eq(7)
      expect(StockExport.find(JSON.parse(response.body)["export_id"]).workflow_status).to eq("shipped")
    end

    it "requires a reference" do
      stock = create_stock(quantity: 10)

      post inventory_exports_company_operations_path(company, operation), params: {
        warehouse_id: warehouse.id,
        stock_export: { stock_id: stock.id, quantity: 3, reference: "" }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to include("Enter a reference for this export.")
      expect(stock.reload.quantity).to eq(10)
    end
  end

  describe "POST #create_adjustment" do
    it "sets the new on hand and stores the reason" do
      stock = create_stock(quantity: 20, pending: 0)

      post inventory_adjustments_company_operations_path(company, operation), params: {
        warehouse_id: warehouse.id,
        adjustment: { stock_id: stock.id, new_on_hand: 19, reason: "Damage", note: "Torn" }
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(stock.reload.quantity).to eq(19)
      expect(company.stock_adjustments.last.reason).to eq("Damage")
    end

    it "blocks a value below reserved" do
      stock = create_stock(quantity: 20, pending: 12)

      post inventory_adjustments_company_operations_path(company, operation), params: {
        warehouse_id: warehouse.id,
        adjustment: { stock_id: stock.id, new_on_hand: 10, reason: "Damage" }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to include("On hand cannot be less than the 12 reserved.")
      expect(stock.reload.quantity).to eq(20)
    end
  end

  describe "POST #create_reorder" do
    it "creates one purchase draft and returns the same one on the second press" do
      supplier = create(:supplier, company: company, name: "Fresh Foods")
      product.update!(default_supplier: supplier)
      stock = create_stock(quantity: 2)

      post inventory_reorder_company_operations_path(company, operation), params: {
        warehouse_id: warehouse.id,
        reorder: { stock_id: stock.id, quantity: 8 }
      }, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["purchase"]["code"]).to start_with("PUR-")
      expect(company.purchases.count).to eq(1)
      expect(company.purchases.first.business_type).to eq("stock_reorder")

      post inventory_reorder_company_operations_path(company, operation), params: {
        warehouse_id: warehouse.id,
        reorder: { stock_id: stock.id, quantity: 8 }
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["existing"]).to be(true)
      expect(company.purchases.count).to eq(1)
    end
  end

  describe "cycles counts" do
    it "starts, saves progress and submits variances" do
      stock = create_stock(quantity: 10)

      post inventory_counts_company_operations_path(company, operation), params: { warehouse_id: warehouse.id }, as: :json
      expect(response).to have_http_status(:ok)
      count = JSON.parse(response.body)["count"]
      expect(count["status"]).to eq("in_progress")
      line = count["lines"].first

      patch inventory_count_update_company_operations_path(company, operation, count["id"]), params: {
        warehouse_id: warehouse.id,
        count: { lines: [ { id: line["id"], counted_quantity: 8 } ] }
      }, as: :json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("count", "net_variance")).to eq(-2)

      post inventory_count_submit_company_operations_path(company, operation, count["id"]), params: {
        warehouse_id: warehouse.id
      }, as: :json
      expect(response).to have_http_status(:ok)
      expect(stock.reload.quantity).to eq(8)
      expect(StockCount.find(count["id"]).status).to eq("completed")
    end

    it "blocks a second open count" do
      create_stock(quantity: 10)
      post inventory_counts_company_operations_path(company, operation), params: { warehouse_id: warehouse.id }, as: :json
      expect(response).to have_http_status(:ok)

      post inventory_counts_company_operations_path(company, operation), params: { warehouse_id: warehouse.id }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to include("A count is already in progress for this warehouse.")
    end
  end
end
