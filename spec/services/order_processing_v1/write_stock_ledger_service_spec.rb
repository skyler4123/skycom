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

    it "mutates quantity through the ledger callback and consumes the pay-time hold" do
      stock.reserve_stock!(2) # the pay-time reservation

      described_class.call(order: order)

      expect(stock.reload.quantity).to eq(8)
      expect(stock.reload.pending).to eq(0)
      expect(stock.available_count).to eq(8)
    end

    it "anchors the ledger row on the order" do
      described_class.call(order: order)

      expect(StockTransaction.last.appoint_for).to eq(order)
    end

    it "uses the stock persisted on the order appointment when present" do
      other_warehouse = create(:warehouse, company: company)
      branch_stock = create(:stock, company: company, product: product, warehouse: other_warehouse, quantity: 50)
      oa.update!(stock_id: branch_stock.id)

      described_class.call(order: order)

      expect(branch_stock.reload.quantity).to eq(48)
      expect(stock.reload.quantity).to eq(10)
    end

    it "falls back to branch-scoped resolution for legacy lines without stock_id" do
      branch_warehouse = create(:warehouse, company: company, branch: branch)
      branch_stock = create(:stock, company: company, product: product, warehouse: branch_warehouse, quantity: 20)
      branch_stock.reserve_stock!(2)

      described_class.call(order: order)

      expect(branch_stock.reload.quantity).to eq(18)
      expect(branch_stock.reload.pending).to eq(0)
      expect(stock.reload.quantity).to eq(10)
    end
  end
end
