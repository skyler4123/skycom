require "rails_helper"

RSpec.describe OrderProcessingV1::UpdateStockBalancesService do
  describe ".call" do
    let(:company) { create(:company) }
    let(:branch) { create(:branch, company: company) }
    let(:product) { create(:product, company: company, branch: branch) }
    let(:warehouse) { create(:warehouse, company: company) }
    let(:customer) { create(:customer, company: company) }
    let!(:stock) { create(:stock, company: company, product: product, warehouse: warehouse, quantity: 10, reserved_quantity: 5) }
    let(:order) { create(:order, company: company, branch: branch, customer: customer, workflow_status: :paid) }
    let!(:oa) do
      OrderAppointment.create!(
        company: company,
        order: order,
        appoint_to: product,
        quantity: 2,
        unit_price: 50,
        total_price: 100
      )
    end

    it "reduces quantity and reserved_quantity" do
      described_class.call(order: order)
      stock.reload
      expect(stock.quantity).to eq(8)
      expect(stock.reserved_quantity).to eq(3)
    end

    it "returns updated stock ids" do
      result = described_class.call(order: order)
      expect(result[:updated]).to include(stock.id)
    end
  end
end
