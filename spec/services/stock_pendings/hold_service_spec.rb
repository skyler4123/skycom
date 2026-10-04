require "rails_helper"

RSpec.describe StockPendings::HoldService do
  let(:company) { create(:company) }
  let(:warehouse) { create(:warehouse, company: company) }
  let(:product) { create(:product, company: company) }
  let(:stock) do
    Seed::StockService.create(
      company: company, warehouse: warehouse,
      branch: warehouse.branch, product_id: product.id, quantity: 50
    )
  end

  it "creates a holding pending plus one anchored hold ledger row" do
    result = described_class.call(
      company: company, warehouse: warehouse, stock: stock,
      quantity: 8, business_type: :manual, name: "Event hold"
    )

    expect(result[:success]).to be(true)
    pending = result[:stock_pending]
    expect(pending.workflow_status).to eq("pending")
    expect(pending.business_type).to eq("manual")
    expect(pending.released_at).to be_nil
    expect(stock.reload.pending).to eq(8)

    ledger = StockTransaction.where(transaction_type: :hold)
    expect(ledger.count).to eq(1)
    expect(ledger.first.appoint_for).to eq(pending)
    expect(ledger.first.quantity).to eq(8)
  end

  it "rolls back everything when stock is insufficient" do
    result = described_class.call(
      company: company, warehouse: warehouse, stock: stock, quantity: 51
    )

    expect(result[:success]).to be(false)
    expect(result[:errors]).to be_present
    expect(StockPending.count).to eq(0)
    expect(StockTransaction.where(transaction_type: :hold).count).to eq(0)
    expect(stock.reload.pending).to eq(0)
  end

  it "rejects a warehouse that does not own the stock" do
    other_warehouse = create(:warehouse, company: company)

    result = described_class.call(
      company: company, warehouse: other_warehouse, stock: stock, quantity: 5
    )

    expect(result[:success]).to be(false)
    expect(StockPending.count).to eq(0)
  end
end
