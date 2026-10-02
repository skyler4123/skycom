# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::StockPendingsController", type: :request do
  let(:company) { create(:company) }
  let(:warehouse) { create(:warehouse, company: company) }
  let(:product) { create(:product, company: company) }
  let!(:stock) do
    Seed::StockService.create(
      company: company, warehouse: warehouse,
      branch: warehouse.branch, product_id: product.id, quantity: 20
    )
  end
  let(:employee) { create(:employee, company: company) }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  before { get sign_in_for_test_path(email: company.user.email) }

  def create_params(qty = 5)
    { stock_pending: { stock_id: stock.id, quantity: qty, business_type: "manual", name: "Event hold" } }
  end

  describe "GET #index" do
    it "returns the company's pendings with a pagination block" do
      StockPendings::HoldService.call(
        company: company, warehouse: warehouse, stock: stock, quantity: 3
      )

      get company_stock_pendings_path(company), as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["stock_pendings"].size).to eq(1)
      expect(body["stock_pendings"].first["quantity"]).to eq(3)
      expect(body).to have_key("pagination")
      expect(body["warehouses"].map { |w| w["id"] }).to include(warehouse.id)
    end

    it "scopes to the current company" do
      other_company = create(:company)
      other_warehouse = create(:warehouse, company: other_company)
      other_product = create(:product, company: other_company)
      other_stock = Seed::StockService.create(
        company: other_company, warehouse: other_warehouse,
        branch: other_warehouse.branch, product_id: other_product.id, quantity: 5
      )
      StockPendings::HoldService.call(
        company: other_company, warehouse: other_warehouse, stock: other_stock, quantity: 2
      )

      get company_stock_pendings_path(company), as: :json

      expect(response.parsed_body["stock_pendings"]).to be_empty
    end

    it "returns 403 for an employee without read permission" do
      get sign_in_for_test_path(email: employee.user.email)

      get company_stock_pendings_path(company), as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET #new" do
    it "returns warehouses and stocks reference data" do
      get new_company_stock_pending_path(company), as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to have_key("warehouses")
      expect(response.parsed_body).to have_key("stocks")
    end

    it "scopes stocks to the requested warehouse" do
      other_warehouse = create(:warehouse, company: company)

      get new_company_stock_pending_path(company), params: { warehouse_id: other_warehouse.id }, as: :json

      expect(response.parsed_body["stocks"]).to be_empty
    end
  end

  it "has no destroy route" do
    delete company_stock_pending_path(company, SecureRandom.uuid), as: :json

    expect(response).to have_http_status(:not_found)
  end

  describe "POST #create" do
    it "holds stock and returns the pending" do
      post company_stock_pendings_path(company), params: create_params, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["stock_pending"]["quantity"]).to eq(5)
      expect(stock.reload.pending).to eq(5)
    end

    it "renders 422 with errors and persists nothing when stock is insufficient" do
      post company_stock_pendings_path(company), params: create_params(99), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to be_present
      expect(StockPending.count).to eq(0)
      expect(stock.reload.pending).to eq(0)
    end

    it "rejects system business types from the UI API" do
      post company_stock_pendings_path(company),
        params: { stock_pending: { stock_id: stock.id, quantity: 1, business_type: "pos" } }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(StockPending.count).to eq(0)
    end

    it "renders 404 for a foreign stock" do
      foreign_stock = create(:stock)

      post company_stock_pendings_path(company),
        params: { stock_pending: { stock_id: foreign_stock.id, quantity: 1 } }, as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "returns 403 for an employee without create permission" do
      get sign_in_for_test_path(email: employee.user.email)

      post company_stock_pendings_path(company), params: create_params, as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST #release / #cancel" do
    let!(:pending) do
      StockPendings::HoldService.call(
        company: company, warehouse: warehouse, stock: stock, quantity: 4
      )[:stock_pending]
    end

    it "releases the hold and stamps released_at" do
      post release_company_stock_pending_path(company, pending), as: :json

      expect(response).to have_http_status(:ok)
      expect(pending.reload.workflow_status).to eq("completed")
      expect(pending.reload.released_at).to be_present
      expect(stock.reload.pending).to eq(0)
    end

    it "cancels the hold" do
      post cancel_company_stock_pending_path(company, pending), as: :json

      expect(response).to have_http_status(:ok)
      expect(pending.reload.workflow_status).to eq("cancelled")
      expect(stock.reload.pending).to eq(0)
    end

    it "renders 422 when already released" do
      StockPendings::ReleaseService.call(stock_pending: pending)

      post release_company_stock_pending_path(company, pending), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to be_present
    end
  end

  describe "PATCH #update" do
    let!(:pending) do
      StockPendings::HoldService.call(
        company: company, warehouse: warehouse, stock: stock, quantity: 4
      )[:stock_pending]
    end

    it "updates name and reason" do
      patch company_stock_pending_path(company, pending),
        params: { stock_pending: { name: "Renamed", reason: "Counted" } }, as: :json

      expect(response).to have_http_status(:ok)
      expect(pending.reload.name).to eq("Renamed")
    end

    it "rejects quantity changes with 422" do
      patch company_stock_pending_path(company, pending),
        params: { stock_pending: { quantity: 9 } }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(pending.reload.quantity).to eq(4)
    end
  end
end
