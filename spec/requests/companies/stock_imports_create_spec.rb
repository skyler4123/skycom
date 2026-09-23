require 'rails_helper'

RSpec.describe "Companies::StockImportsController#create", type: :request do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:warehouse) { create(:warehouse, company: company) }
  let(:product) { create(:product, company: company) }
  let!(:stock) do
    Stock.create!(company: company, warehouse: warehouse, product: product,
      quantity: 5, pending: 0, name: "Imp Stock", code: "STK-RQI")
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

  def post_import
    post company_stock_imports_path(company), params: {
      stock_import: { warehouse_id: warehouse.id, name: "Supplier delivery", business_type: "purchase" },
      stock_items: [ { stock_id: stock.id, quantity: 3 } ]
    }, as: :json
  end

  it "creates the document, ledger row, and increases stock in one transaction" do
    expect {
      post_import
    }.to change(StockTransaction, :count).by(1)

    expect(response).to have_http_status(:ok)
    expect(stock.reload.quantity).to eq(8)
    expect(stock.available_count).to eq(8)

    import = StockImport.order(:created_at).last
    expect(import.workflow_status).to eq("received")
    expect(import.quantity).to eq(3)
    expect(import.product_id).to eq(product.id)
    expect(StockTransaction.find_by(appoint_for_type: "StockImport", appoint_for_id: import.id))
      .to be_present
  end

  it "renders 422 and persists nothing for an unknown stock id" do
    expect {
      post company_stock_imports_path(company), params: {
        stock_import: { warehouse_id: warehouse.id },
        stock_items: [ { stock_id: "00000000-0000-0000-0000-000000000000", quantity: 1 } ]
      }, as: :json
    }.not_to change(StockImport, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["errors"]).to be_present
  end
end
