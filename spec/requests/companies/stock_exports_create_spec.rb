require 'rails_helper'

RSpec.describe "Companies::StockExportsController#create", type: :request do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:warehouse) { create(:warehouse, company: company) }
  let(:product) { create(:product, company: company) }
  let!(:stock) do
    Stock.create!(company: company, warehouse: warehouse, product: product,
      quantity: 10, pending: 4, name: "Exp Stock", code: "STK-RQE")
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

  it "creates the document and removes available stock" do
    post company_stock_exports_path(company), params: {
      stock_export: { warehouse_id: warehouse.id, name: "Damaged write-off", business_type: "damaged" },
      stock_items: [ { stock_id: stock.id, quantity: 5 } ]
    }, as: :json

    expect(response).to have_http_status(:ok)
    expect(stock.reload.quantity).to eq(5)
    expect(stock.reload.pending).to eq(4) # hold untouched
    export = StockExport.order(:created_at).last
    expect(export.workflow_status).to eq("shipped")
  end

  it "renders 422 and persists nothing when a line exceeds available stock" do
    expect {
      post company_stock_exports_path(company), params: {
        stock_export: { warehouse_id: warehouse.id },
        stock_items: [ { stock_id: stock.id, quantity: 7 } ] # only 6 available
      }, as: :json
    }.not_to change(StockExport, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["errors"].join).to match(/Insufficient stock: available 6/)
    expect(StockItemAppointment.count).to eq(0)
    expect(StockTransaction.count).to eq(0)
    expect(stock.reload.quantity).to eq(10)
  end
end
