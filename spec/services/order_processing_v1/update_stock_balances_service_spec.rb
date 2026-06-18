require "rails_helper"

RSpec.describe OrderProcessingV1::UpdateStockBalancesService do
  describe ".call" do
    let(:company) { create(:company) }
    let(:branch) { create(:branch, company: company) }
    let(:product) { create(:product, company: company, branch: branch) }
    let(:warehouse) { create(:warehouse, company: company) }
    let(:customer) { create(:customer, company: company) }
    let!(:stock) { create(:stock, company: company, product: product, warehouse: warehouse, quantity: 10, reorder: 5) }
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

    it "reduces quantity and reorder" do
      described_class.call(order: order)
      stock.reload
      expect(stock.quantity).to eq(8)
      expect(stock.reorder).to eq(3)
    end

    it "returns updated stock ids" do
      result = described_class.call(order: order)
      expect(result[:updated]).to include(stock.id)
    end

    context "with multiple items" do
      let(:product2) { create(:product, company: company, branch: branch) }
      let!(:stock2) { create(:stock, company:, product: product2, warehouse:, quantity: 20, reorder: 5) }
      let!(:oa2) do
        OrderAppointment.create!(
          company: company, order: order, appoint_to: product2,
          quantity: 3, unit_price: 15, total_price: 45
        )
      end

      it "reduces both stocks" do
        described_class.call(order: order)
        stock.reload
        stock2.reload
        expect(stock.quantity).to eq(8)
        expect(stock.reorder).to eq(3)
        expect(stock2.quantity).to eq(17)
        expect(stock2.reorder).to eq(2)
      end

      it "returns both stock ids" do
        result = described_class.call(order: order)
        expect(result[:updated]).to contain_exactly(stock.id, stock2.id)
      end
    end
  end
end
