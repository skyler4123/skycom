require "rails_helper"

RSpec.describe OrderProcessingV1::FinalizeJob do
  describe "#perform" do
    let(:company) { create(:company) }
    let(:branch) { create(:branch, company: company) }
    let(:product) { create(:product, company: company, branch: branch) }
    let(:warehouse) { create(:warehouse, company: company) }
    let!(:stock) { create(:stock, company: company, product: product, warehouse: warehouse, quantity: 10, reserved_quantity: 5) }
    let(:customer) { create(:customer, company: company) }
    let(:category) { create(:category, company: company, resource_name: "orders") }
    let(:order) { create(:order, company: company, branch: branch, customer: customer, category: category, workflow_status: :paid) }
    let!(:oa) do
      order.order_appointments.create!(
        company: company,
        appoint_to: product,
        quantity: 2,
        unit_price: 50,
        total_price: 100
      )
    end

    it "creates StockTransaction, updates stock, and creates StockExport" do
      expect {
        described_class.perform_now(order.id)
      }.to change(StockTransaction, :count).by(1)
       .and change(StockExport, :count).by(1)

      stock.reload
      expect(stock.quantity).to eq(8)
      expect(stock.reserved_quantity).to eq(3)
    end

    it "is idempotent" do
      described_class.perform_now(order.id)
      expect {
        described_class.perform_now(order.id)
      }.to_not change(StockTransaction, :count)
    end
  end
end
