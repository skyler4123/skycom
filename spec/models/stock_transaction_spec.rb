require 'rails_helper'

RSpec.describe StockTransaction, type: :model do
  let(:company) { create(:company) }
  let(:product) { create(:product, company: company) }
  let(:warehouse) { create(:warehouse, company: company) }
  let!(:stock) do
    Stock.create!(
      company: company, warehouse: warehouse, product: product,
      quantity: 10, pending: 0, name: "Ledger Stock", code: "STK-LGR"
    )
  end

  def build_transaction(direction:, quantity:, warehouse_ref: warehouse)
    StockTransaction.new(
      company: company, warehouse: warehouse_ref, product: product,
      category: stock.category, property_mapping: stock.property_mapping,
      direction: direction, transaction_type: :export, quantity: quantity
    )
  end

  describe "enums" do
    it { should define_enum_for(:direction).with_values(add: 0, remove: 1) }
    it { should define_enum_for(:transaction_type).with_values(import: 0, export: 1, transfer: 2, adjustment: 3) }
  end

  describe "#recalibrate_stock_metrics (hardened single quantity mutator)" do
    it "adds quantity for add direction" do
      build_transaction(direction: :add, quantity: 4).save!

      expect(stock.reload.quantity).to eq(14)
    end

    it "removes quantity for remove direction" do
      build_transaction(direction: :remove, quantity: 4).save!

      expect(stock.reload.quantity).to eq(6)
    end

    it "syncs the Redis available counter" do
      build_transaction(direction: :remove, quantity: 3).save!

      expect(stock.reload.available_count).to eq(7)
    end

    it "raises and creates nothing when removal would go negative" do
      expect {
        build_transaction(direction: :remove, quantity: 11).save!
      }.to raise_error(StockMovementService::Error, /Insufficient stock/)

      expect(StockTransaction.count).to eq(0)
      expect(stock.reload.quantity).to eq(10)
    end

    it "does not lazily create a missing stock row" do
      other_warehouse = create(:warehouse, company: company)

      expect {
        build_transaction(direction: :add, quantity: 5, warehouse_ref: other_warehouse).save!
      }.to raise_error(ActiveRecord::RecordNotFound)

      expect(Stock.where(warehouse: other_warehouse, product: product).count).to eq(0)
    end
  end
end
