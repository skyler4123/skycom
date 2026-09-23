require 'rails_helper'

RSpec.describe StockMovementService::Purchases::CompleteService, type: :model do
  let(:company) { create(:company) }
  let(:warehouse) { create(:warehouse, company: company) }
  let(:employee) { create(:employee, company: company) }
  let(:product) { create(:product, company: company) }
  let(:purchase) { create(:purchase, company: company, warehouse: warehouse, name: "Pen restock #{SecureRandom.hex(3)}") }
  let!(:purchase_item) { create(:purchase_item, company: company, product: product, name: "Ballpoint Pen") }

  before do
    purchase.purchase_item_appointments.create!(
      company: company, purchase_item: purchase_item, quantity: 5,
      unit_price: 2.5, total_price: 12.5
    )
  end

  it "creates a received StockImport and increases the destination warehouse stock" do
    expect {
      result = described_class.call(purchase: purchase, employee: employee)
      expect(result[:success]).to be true
    }.to change(StockTransaction, :count).by(1)

    stock = Stock.find_by!(company: company, warehouse: warehouse, product: product)
    expect(stock.quantity).to eq(5)

    import = StockImport.find_by(appoint_from_type: "Purchase", appoint_from_id: purchase.id)
    expect(import).to be_present
    expect(import.workflow_status_received?).to be true
    expect(import.purchase?).to be true
    expect(import.stock_item_appointments.count).to eq(1)

    txn = StockTransaction.find_by(appoint_for_type: "StockImport", appoint_for_id: import.id)
    expect(txn).to be_add
    expect(txn.appoint_by).to eq(employee)
  end

  it "creates a new Stock row positively when the (warehouse, product) pair has none" do
    expect(Stock.where(company: company, product: product).count).to eq(0)

    described_class.call(purchase: purchase, employee: employee)

    stock = Stock.find_by!(company: company, warehouse: warehouse, product: product)
    expect(stock.quantity).to eq(5)
  end

  it "is idempotent — second call skips" do
    described_class.call(purchase: purchase, employee: employee)
    expect {
      result = described_class.call(purchase: purchase, employee: employee)
      expect(result[:skipped]).to be true
    }.not_to change(StockTransaction, :count)
  end
end
