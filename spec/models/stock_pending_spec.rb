require "rails_helper"

RSpec.describe StockPending, type: :model do
  let(:company) { create(:company) }
  let(:warehouse) { create(:warehouse, company: company) }
  let(:product) { create(:product, company: company) }
  let(:stock) do
    Seed::StockService.create(
      company: company, warehouse: warehouse,
      branch: warehouse.branch, product_id: product.id, quantity: 50
    )
  end

  def build_pending(**overrides)
    StockPending.new({
      company: company, warehouse: warehouse,
      stock: stock, product: product,
      quantity: 5, workflow_status: :pending, business_type: :manual
    }.merge(overrides))
  end

  it "creates a holding pending with nil released_at" do
    pending = build_pending
    pending.save!
    expect(pending.workflow_status).to eq("pending")
    expect(pending.released_at).to be_nil
    expect(pending.status_changed_at).to be_present
  end

  it "rejects warehouse mismatch with stock warehouse" do
    other_warehouse = create(:warehouse, company: company)
    expect(build_pending(warehouse: other_warehouse)).not_to be_valid
  end

  it "rejects product mismatch with stock product" do
    other_product = create(:product, company: company)
    expect(build_pending(product: other_product)).not_to be_valid
  end

  it "rejects cross-company stock" do
    other_company = create(:company)
    other_warehouse = create(:warehouse, company: other_company)
    other_product = create(:product, company: other_company)
    other_stock = Seed::StockService.create(
      company: other_company, warehouse: other_warehouse,
      branch: other_warehouse.branch, product_id: other_product.id, quantity: 10
    )
    expect(build_pending(stock: other_stock)).not_to be_valid
  end

  it "rejects non-positive quantity" do
    expect(build_pending(quantity: 0)).not_to be_valid
  end

  it "release! stamps released_at and second call returns false" do
    pending = build_pending
    pending.save!
    expect(pending.release!).to be(true)
    expect(pending.workflow_status).to eq("completed")
    expect(pending.released_at).to be_present
    expect(pending.release!).to be(false)
  end

  it "cancel! stamps released_at and second call returns false" do
    pending = build_pending
    pending.save!
    expect(pending.cancel!).to be(true)
    expect(pending.workflow_status).to eq("cancelled")
    expect(pending.released_at).to be_present
    expect(pending.cancel!).to be(false)
  end

  it "blocks destroy while holding" do
    pending = build_pending
    pending.save!
    expect { pending.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
  end

  it "allows destroy once released" do
    pending = build_pending
    pending.save!
    pending.release!
    expect { pending.destroy! }.not_to raise_error
  end
end
