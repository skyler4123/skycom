require "rails_helper"

RSpec.describe OrderProcessingV1::FinalizeOrderService do
  describe ".call" do
    let(:company) { create(:company) }
    let(:branch) { create(:branch, company: company) }
    let(:product) { create(:product, company: company, branch: branch) }
    let(:warehouse) { Seed::WarehouseService.create(company: company, branch: branch) }
    let!(:stock) { create(:stock, company: company, product: product, warehouse: warehouse, quantity: 10) }
    let(:order) { create(:order, company: company, branch: branch, workflow_status: :paid) }
    let!(:oa) { create(:order_appointment, order: order, company: company, appoint_to: product, quantity: 2, unit_price: 50, total_price: 100) }

    it "creates StockExport records for each item" do
      expect { described_class.call(order: order) }.to change(StockExport, :count).by(1)
      export = StockExport.last
      expect(export.business_type).to eq("sale")
      expect(export.quantity).to eq(2)
    end
  end
end
