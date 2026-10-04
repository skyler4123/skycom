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
      OrderProductAppointment.create!(
        company: company,
        order: order,
        product: product,
        quantity: 2,
        unit_price: 50,
        total_price: 100
      )
    end

    def pay_hold(target_stock, qty)
      StockPendings::HoldService.call(
        company: company, warehouse: target_stock.warehouse, stock: target_stock,
        quantity: qty, business_type: :pos
      )
    end

    it "creates StockTransaction records" do
      pay_hold(stock, 2)
      oa.update!(stock_id: stock.id)

      expect { described_class.call(order: order) }.to change(StockTransaction, :count).by(2)
      trx = StockTransaction.where(transaction_type: :export).last
      expect(trx.direction).to eq("remove")
      expect(trx.quantity).to eq(2)
    end

    it "writes exactly two ledger rows per line (quantity remove + pending release)" do
      pay_hold(stock, 2)
      oa.update!(stock_id: stock.id)

      described_class.call(order: order)

      expect(StockTransaction.where(transaction_type: :export).count).to eq(1)
      expect(StockTransaction.where(transaction_type: :release).count).to eq(1)
    end

    it "returns count of lines finalized" do
      pay_hold(stock, 2)
      oa.update!(stock_id: stock.id)

      result = described_class.call(order: order)
      expect(result[:count]).to eq(1)
    end

    it "mutates quantity through the ledger callback and consumes the pay-time hold" do
      pay_hold(stock, 2) # the pay-time reservation
      oa.update!(stock_id: stock.id)

      described_class.call(order: order)

      expect(stock.reload.quantity).to eq(8)
      expect(stock.reload.pending).to eq(0)
      expect(stock.available_count).to eq(8)
    end

    it "anchors the ledger row on the order" do
      pay_hold(stock, 2)
      oa.update!(stock_id: stock.id)

      described_class.call(order: order)

      expect(StockTransaction.where(transaction_type: :export).last.appoint_for).to eq(order)
    end

    it "uses the stock persisted on the order appointment when present" do
      other_warehouse = create(:warehouse, company: company)
      branch_stock = create(:stock, company: company, product: product, warehouse: other_warehouse, quantity: 50)
      oa.update!(stock_id: branch_stock.id)
      pay_hold(branch_stock, 2) # the pay-time reservation for this line

      described_class.call(order: order)

      expect(branch_stock.reload.quantity).to eq(48)
      expect(stock.reload.quantity).to eq(10)
    end

    it "falls back to branch-scoped resolution for legacy lines without stock_id" do
      branch_warehouse = create(:warehouse, company: company, branch: branch)
      branch_stock = create(:stock, company: company, product: product, warehouse: branch_warehouse, quantity: 20)
      pay_hold(branch_stock, 2)

      described_class.call(order: order)

      expect(branch_stock.reload.quantity).to eq(18)
      expect(branch_stock.reload.pending).to eq(0)
      expect(stock.reload.quantity).to eq(10)
    end

    it "never consumes an unrelated hold on legacy lines" do
      pay_hold(stock, 3)
      other_hold = StockPendings::HoldService.call(
        company: company, warehouse: stock.warehouse, stock: stock,
        quantity: 3, business_type: :manual
      )[:stock_pending]

      described_class.call(order: order)

      expect(stock.reload.quantity).to eq(8)
      expect(stock.reload.pending).to eq(3)
      expect(other_hold.reload.workflow_status).to eq("pending")
    end

    it "fails fast for pay-persisted lines whose hold is gone (never eats another hold)" do
      oa.update!(stock_id: stock.id)
      # No reservation: pending is 0 — the hold this line claims does not exist.

      expect {
        described_class.call(order: order)
      }.to raise_error(StockMovementService::Error, /Insufficient stock/)

      expect(stock.reload.quantity).to eq(10)
      expect(stock.reload.pending).to eq(0)
    end
  end
end
