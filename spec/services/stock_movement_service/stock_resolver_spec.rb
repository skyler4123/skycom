require 'rails_helper'

RSpec.describe StockMovementService::StockResolver, type: :model do
  let(:company) { create(:company) }
  let(:product) { create(:product, company: company) }
  let(:warehouse) { create(:warehouse, company: company, branch: create(:branch, company: company)) }

  it "returns the existing stock row when present" do
    existing = Stock.create!(company: company, warehouse: warehouse, product: product, quantity: 7, name: "Existing", code: "STK-EX1")

    expect(described_class.resolve!(company: company, warehouse: warehouse, product: product)).to eq(existing)
  end

  it "creates a positive zero-quantity stock row when absent" do
    stock = described_class.resolve!(company: company, warehouse: warehouse, product: product)

    expect(stock).to be_persisted
    expect(stock.quantity).to eq(0)
    expect(stock.pending).to eq(0)
    expect(stock.branch_id).to eq(warehouse.branch_id)
    expect(stock.category.resource_name).to eq("stocks")
    expect(stock.property_mapping).to be_present
    expect(stock.code).to be_present
  end

  it "reuses the same stocks category for the company" do
    first = described_class.resolve!(company: company, warehouse: warehouse, product: product)
    other_product = create(:product, company: company)
    second = described_class.resolve!(company: company, warehouse: warehouse, product: other_product)

    expect(second.category_id).to eq(first.category_id)
  end
end
