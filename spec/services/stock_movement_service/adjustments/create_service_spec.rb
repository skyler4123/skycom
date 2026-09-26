require 'rails_helper'

RSpec.describe StockMovementService::Adjustments::CreateService, type: :model do
  let(:company) { create(:company) }
  let(:product) { create(:product, company: company) }
  let(:warehouse) { create(:warehouse, company: company) }
  let!(:stock) do
    Stock.create!(company: company, warehouse: warehouse, product: product, quantity: 8, pending: 2, name: "Adj Stock", code: "STK-ADJ")
  end
  let(:employee) { create(:employee, company: company) }

  def build_adjustment(direction:, quantity:)
    adjustment = StockAdjustment.new(
      company: company, warehouse: warehouse,
      category: stock.category, property_mapping: stock.property_mapping,
      code: "STKAD-#{SecureRandom.hex(4).upcase}", name: "Stock take",
      direction: direction, reason: "Cycle count", workflow_status: :pending
    )
    adjustment.stock_item_appointments.build(company: company, stock: stock, quantity: quantity)
    adjustment
  end

  it "increases stock for an increase adjustment" do
    adjustment = build_adjustment(direction: :increase, quantity: 3)

    ActiveRecord::Base.transaction do
      adjustment.save!
      described_class.execute!(document: adjustment, employee: employee)
    end

    expect(stock.reload.quantity).to eq(11)
    expect(adjustment.reload.workflow_status_completed?).to be true
    txn = StockTransaction.find_by(appoint_for_type: "StockAdjustment")
    expect(txn).to be_add
    expect(txn).to be_adjustment
  end

  it "decreases stock for a decrease adjustment" do
    adjustment = build_adjustment(direction: :decrease, quantity: 5) # available 6

    ActiveRecord::Base.transaction do
      adjustment.save!
      described_class.execute!(document: adjustment, employee: employee)
    end

    expect(stock.reload.quantity).to eq(3)
    txn = StockTransaction.find_by(appoint_for_type: "StockAdjustment")
    expect(txn).to be_remove
  end

  it "fails fast when a decrease would consume pending units" do
    adjustment = build_adjustment(direction: :decrease, quantity: 7) # available 6

    expect {
      ActiveRecord::Base.transaction do
        adjustment.save!
        described_class.execute!(document: adjustment, employee: employee)
      end
    }.to raise_error(StockMovementService::Error, /Insufficient stock: available 6/)

    expect(stock.reload.quantity).to eq(8)
  end
end
