require 'rails_helper'

RSpec.describe StockTransaction, type: :model do
  let(:company) { create(:company) }
  let(:product) { create(:product, company: company) }
  let(:warehouse) { create(:warehouse, company: company) }
  let!(:stock) do
    Stock.create!(
      company: company, warehouse: warehouse, product: product,
      quantity: 10, pending: 2, name: "Hold Stock", code: "STK-HLD"
    )
  end

  def build_hold(quantity:, warehouse_ref: warehouse)
    StockTransaction.new(
      company: company, warehouse: warehouse_ref, product: product,
      category: stock.category, property_mapping: stock.property_mapping,
      direction: :remove, transaction_type: :hold, quantity: quantity
    )
  end

  def build_release(quantity:, warehouse_ref: warehouse)
    StockTransaction.new(
      company: company, warehouse: warehouse_ref, product: product,
      category: stock.category, property_mapping: stock.property_mapping,
      direction: :add, transaction_type: :release, quantity: quantity
    )
  end

  it "hold increases pending without touching quantity" do
    build_hold(quantity: 3).save!

    stock.reload
    expect(stock.pending).to eq(5)
    expect(stock.quantity).to eq(10)
  end

  it "hold decreases the Redis available counter" do
    build_hold(quantity: 3).save!

    expect(stock.reload.available_count).to eq(5)
  end

  it "hold raises and creates nothing when available is insufficient" do
    expect {
      build_hold(quantity: 9).save!
    }.to raise_error(StockMovementService::Error, /Insufficient stock/)

    expect(StockTransaction.count).to eq(0)
    expect(stock.reload.pending).to eq(2)
  end

  it "release decreases pending without touching quantity" do
    build_release(quantity: 2).save!

    stock.reload
    expect(stock.pending).to eq(0)
    expect(stock.quantity).to eq(10)
  end

  it "release raises and creates nothing on over-release" do
    expect {
      build_release(quantity: 3).save!
    }.to raise_error(StockMovementService::Error, /Insufficient stock/)

    expect(StockTransaction.count).to eq(0)
    expect(stock.reload.pending).to eq(2)
  end
end
