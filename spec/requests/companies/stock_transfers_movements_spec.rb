require 'rails_helper'

RSpec.describe "Companies::StockTransfersController movements", type: :request do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company) }
  let(:source_warehouse) { create(:warehouse, company: company, branch: branch) }
  let(:destination_warehouse) { create(:warehouse, company: company) }
  let(:product) { create(:product, company: company) }
  let!(:stock) do
    Stock.create!(company: company, warehouse: source_warehouse, product: product,
      quantity: 10, pending: 0, name: "Trf Stock", code: "STK-TRF")
  end
  let!(:transfer) do
    category = stock.category
    StockTransfer.create!(
      company: company, branch: branch,
      warehouse: source_warehouse, destination_warehouse: destination_warehouse,
      category: category, property_mapping: category.default_property_mapping,
      code: "STKTR-TEST1", name: "Move", business_type: :transfer,
      workflow_status: :pending
    ).tap do |t|
      t.stock_item_appointments.create!(company: company, stock: stock, quantity: 4)
    end
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

  describe "POST initiate" do
    it "holds source units and marks initiated" do
      post initiate_company_stock_transfer_path(company, transfer), as: :json

      expect(response).to have_http_status(:ok)
      expect(stock.reload.pending).to eq(4)
      expect(transfer.reload.workflow_status).to eq("initiated")
    end

    it "renders 422 with errors when the hold fails" do
      transfer.stock_item_appointments.first.update!(quantity: 99)

      post initiate_company_stock_transfer_path(company, transfer), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to be_present
      expect(transfer.reload.workflow_status).to eq("pending")
    end
  end

  describe "POST receive" do
    it "moves quantities with two ledger rows" do
      StockMovementService::Transfers::InitiateService.call(transfer: transfer, employee: nil)

      post receive_company_stock_transfer_path(company, transfer), as: :json

      expect(response).to have_http_status(:ok)
      expect(stock.reload.quantity).to eq(6)
      expect(stock.reload.pending).to eq(0)
      dest_stock = Stock.find_by!(company: company, warehouse: destination_warehouse, product: product)
      expect(dest_stock.quantity).to eq(4)
      expect(StockTransaction.where(transaction_type: :transfer).count).to eq(2)
    end

    it "renders 422 when not initiated" do
      post receive_company_stock_transfer_path(company, transfer), as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "POST cancel" do
    it "releases holds and marks cancelled" do
      StockMovementService::Transfers::InitiateService.call(transfer: transfer, employee: nil)

      post cancel_company_stock_transfer_path(company, transfer), as: :json

      expect(response).to have_http_status(:ok)
      expect(stock.reload.pending).to eq(0)
      expect(transfer.reload.workflow_status).to eq("cancelled")
    end
  end

  describe "POST create" do
    it "builds the document with stock lines without moving anything" do
      expect {
        post company_stock_transfers_path(company), params: {
          stock_transfer: {
            warehouse_id: source_warehouse.id,
            destination_warehouse_id: destination_warehouse.id,
            name: "Restock move"
          },
          stock_items: [ { stock_id: stock.id, quantity: 3 } ]
        }, as: :json
      }.not_to change(StockTransaction, :count)

      expect(response).to have_http_status(:ok)
      expect(stock.reload.pending).to eq(0)
      created = StockTransfer.order(:created_at).last
      expect(created.workflow_status).to eq("pending")
      expect(created.stock_item_appointments.count).to eq(1)
      expect(created.destination_warehouse_id).to eq(destination_warehouse.id)
    end
  end
end
