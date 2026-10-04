require "rails_helper"

RSpec.describe StockPendings::ReleaseService do
  let(:company) { create(:company) }
  let(:warehouse) { create(:warehouse, company: company) }
  let(:product) { create(:product, company: company) }
  let(:stock) do
    Seed::StockService.create(
      company: company, warehouse: warehouse,
      branch: warehouse.branch, product_id: product.id, quantity: 50
    )
  end

  def hold(qty, **overrides)
    StockPendings::HoldService.call(
      **{ company: company, warehouse: warehouse, stock: stock, quantity: qty }.merge(overrides)
    )[:stock_pending]
  end

  it "releases an exact pending and restores availability" do
    pending = hold(8)

    result = described_class.call(stock_pending: pending)

    expect(result[:success]).to be(true)
    expect(pending.reload.workflow_status).to eq("completed")
    expect(pending.reload.released_at).to be_present
    expect(stock.reload.pending).to eq(0)
    expect(StockTransaction.where(transaction_type: :release).count).to eq(1)
  end

  it "cancels an exact pending with the cancel target" do
    pending = hold(8)

    result = described_class.call(stock_pending: pending, target: :cancel)

    expect(result[:success]).to be(true)
    expect(pending.reload.workflow_status).to eq("cancelled")
    expect(stock.reload.pending).to eq(0)
  end

  it "returns failure for an already-released pending" do
    pending = hold(8)
    described_class.call(stock_pending: pending)

    result = described_class.call(stock_pending: pending)

    expect(result[:success]).to be(false)
    expect(StockTransaction.where(transaction_type: :release).count).to eq(1)
  end

  it "releases oldest whole rows first in scope mode" do
    first = hold(5)
    hold(7)

    result = described_class.call(
      company: company, warehouse: warehouse, stock: stock, quantity: 6
    )

    expect(result[:success]).to be(true)
    expect(first.reload.workflow_status).to eq("completed")
    expect(stock.reload.pending).to eq(0)
  end

  it "prefers same-business_type rows in scope mode" do
    manual = hold(4, business_type: :manual)
    pos = hold(4, business_type: :pos)

    result = described_class.call(
      company: company, warehouse: warehouse, stock: stock,
      quantity: 4, business_type: :pos
    )

    expect(result[:success]).to be(true)
    expect(pos.reload.workflow_status).to eq("completed")
    expect(manual.reload.workflow_status).to eq("pending")
  end

  it "rejects a release through a stale holding object" do
    pending = hold(8)
    stale = StockPending.find(pending.id)
    described_class.call(stock_pending: pending)

    result = described_class.call(stock_pending: stale)

    expect(result[:success]).to be(false)
    expect(StockTransaction.where(transaction_type: :release).count).to eq(1)
    expect(stock.reload.pending).to eq(0)
  end
end
