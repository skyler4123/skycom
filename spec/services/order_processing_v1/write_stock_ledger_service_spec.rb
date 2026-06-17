require "rails_helper"

RSpec.describe OrderProcessingV1::WriteStockLedgerService do
  describe ".call" do
    let(:company) { create(:company) }
    let(:branch) { create(:branch, company: company) }
    let(:product) { create(:product, company: company, branch: branch) }
    let(:warehouse) { create(:warehouse, company: company) }
    let(:customer) { create(:customer, company: company) }
    let!(:stock) { create(:stock, company: company, product: product, warehouse: warehouse, quantity: 10) }
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

    it "creates StockTransaction records" do
      expect { described_class.call(order: order) }.to change(StockTransaction, :count).by(1)
      trx = StockTransaction.last
      expect(trx.direction).to eq("remove")
      expect(trx.transaction_type).to eq("export")
      expect(trx.quantity).to eq(2)
    end

    it "returns count of transactions created" do
      result = described_class.call(order: order)
      expect(result[:count]).to eq(1)
    end
  end
end
