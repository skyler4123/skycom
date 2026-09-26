require 'rails_helper'

RSpec.describe StockMovementService::Transfers, type: :model do
  let(:company) { create(:company) }
  let(:product) { create(:product, company: company) }
  let(:source_warehouse) { create(:warehouse, company: company) }
  let(:destination_warehouse) { create(:warehouse, company: company) }
  let!(:source_stock) do
    Stock.create!(company: company, warehouse: source_warehouse, product: product, quantity: 10, pending: 0, name: "Src Stock", code: "STK-SRC")
  end
  let(:employee) { create(:employee, company: company) }
  let!(:transfer) do
    build_transfer(quantity: 4)
  end

  def build_transfer(quantity:, src: source_stock)
    transfer = StockTransfer.new(
      company: company, warehouse: src.warehouse, destination_warehouse: destination_warehouse,
      category: src.category, property_mapping: src.property_mapping,
      code: "STKTR-#{SecureRandom.hex(4).upcase}", name: "Move units",
      business_type: :transfer, workflow_status: :pending
    )
    transfer.stock_item_appointments.build(company: company, stock: src, quantity: quantity)
    transfer.save!
    transfer
  end

  describe "two-phase movement" do
    it "initiates: holds source units without touching quantity or writing ledger rows" do
      result = described_class::InitiateService.call(transfer: transfer, employee: employee)

      expect(result[:success]).to be true
      expect(source_stock.reload.quantity).to eq(10)
      expect(source_stock.reload.pending).to eq(4)
      expect(source_stock.available_count).to eq(6)
      expect(transfer.reload.workflow_status_initiated?).to be true
      expect(transfer.initiated_at).to be_present
      expect(StockTransaction.count).to eq(0)
    end

    it "receives: two ledger rows (remove@source consuming hold + add@dest), quantities applied" do
      described_class::InitiateService.call(transfer: transfer, employee: employee)
      described_class::ReceiveService.call(transfer: transfer.reload, employee: employee)

      expect(source_stock.reload.quantity).to eq(6)
      expect(source_stock.reload.pending).to eq(0)

      dest_stock = Stock.find_by!(company: company, warehouse: destination_warehouse, product: product)
      expect(dest_stock.quantity).to eq(4)

      txns = StockTransaction.where(transaction_type: :transfer)
      expect(txns.count).to eq(2)
      expect(txns.where(direction: :remove).count).to eq(1)
      expect(txns.where(direction: :add).count).to eq(1)
      expect(txns.where(direction: :remove).first.appoint_from).to eq(transfer)
      expect(txns.where(direction: :add).first.appoint_to).to eq(transfer)
      expect(transfer.reload.workflow_status_received?).to be true
      expect(transfer.received_at).to be_present
    end

    it "cancels: releases the hold and marks cancelled" do
      described_class::InitiateService.call(transfer: transfer, employee: employee)
      described_class::CancelService.call(transfer: transfer.reload, employee: employee)

      expect(source_stock.reload.pending).to eq(0)
      expect(source_stock.reload.quantity).to eq(10)
      expect(transfer.reload.workflow_status_cancelled?).to be true
    end

    it "rolls back all holds when a later line cannot be reserved" do
      scarce_product = create(:product, company: company)
      scarce_stock = Stock.create!(company: company, warehouse: source_warehouse, product: scarce_product, quantity: 1, pending: 0, name: "Scarce", code: "STK-SCR")
      transfer2 = build_transfer(quantity: 1, src: scarce_stock)
      transfer2.stock_item_appointments.destroy_all
      transfer2.stock_item_appointments.create!(company: company, stock: source_stock.reload, quantity: 4)
      transfer2.stock_item_appointments.create!(company: company, stock: scarce_stock, quantity: 5)

      expect {
        described_class::InitiateService.call(transfer: transfer2, employee: employee)
      }.to raise_error(StockMovementService::Error, /Insufficient stock to initiate/)

      expect(source_stock.reload.pending).to eq(0)
      expect(scarce_stock.reload.pending).to eq(0)
      expect(transfer2.reload.workflow_status_initiated?).to be false
    end

    it "refuses to receive a transfer that was never initiated" do
      expect {
        described_class::ReceiveService.call(transfer: transfer.reload, employee: employee)
      }.to raise_error(StockMovementService::Error, /must be initiated/)
    end
  end
end
