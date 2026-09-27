require 'rails_helper'

RSpec.describe "Companies::StockAdjustmentsController", type: :request do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:warehouse) { create(:warehouse, company: company) }
  let(:product) { create(:product, company: company) }
  let!(:stock) do
    Stock.create!(company: company, warehouse: warehouse, product: product,
      quantity: 8, pending: 2, name: "Adj Stock", code: "STK-RQA")
  end


  # Request specs POST without a browser CSRF token — disable forgery for the
  # example (same pattern as purchases_controller_spec).
  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  before { get sign_in_for_test_path(email: owner.email) }

  describe "POST create" do
    it "increases stock for an increase adjustment" do
      post company_stock_adjustments_path(company), params: {
        stock_adjustment: {
          warehouse_id: warehouse.id, direction: "increase", reason: "Cycle count up"
        },
        stock_items: [ { stock_id: stock.id, quantity: 3 } ]
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(stock.reload.quantity).to eq(11)
      adjustment = StockAdjustment.order(:created_at).last
      expect(adjustment.workflow_status).to eq("completed")
      expect(adjustment.direction).to eq("increase")
      expect(adjustment.reason).to eq("Cycle count up")
    end

    it "decreases stock but never consumes pending units" do
      post company_stock_adjustments_path(company), params: {
        stock_adjustment: {
          warehouse_id: warehouse.id, direction: "decrease", reason: "Damage"
        },
        stock_items: [ { stock_id: stock.id, quantity: 7 } ] # available 6
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(stock.reload.quantity).to eq(8)
    end
  end

  describe "GET index" do
    it "renders the shell and serves JSON" do
      get company_stock_adjustments_path(company), as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to have_key("stock_adjustments")
    end
  end
end
