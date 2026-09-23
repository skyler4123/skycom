require 'rails_helper'

RSpec.describe StockMovementService::Imports::CreateService, type: :model do
  let(:company) { create(:company) }
  let(:product) { create(:product, company: company) }
  let(:warehouse) { create(:warehouse, company: company) }
  let!(:stock) do
    Stock.create!(company: company, warehouse: warehouse, product: product, quantity: 5, name: "Imp Stock", code: "STK-IMP")
  end
  let(:employee) { create(:employee, company: company) }
  let!(:import) do
    build_import(quantity: 3)
  end

  def build_import(quantity:, stock_ref: stock)
    import = StockImport.new(
      company: company, warehouse: warehouse,
      category: stock_ref.category, property_mapping: stock_ref.property_mapping,
      code: "STKIM-#{SecureRandom.hex(4).upcase}", name: "Restock",
      business_type: :purchase, workflow_status: :pending
    )
    import.stock_item_appointments.build(company: company, stock: stock_ref, quantity: quantity)
    import
  end

  it "adds stock, writes ledger rows, and marks the import received" do
    ActiveRecord::Base.transaction do
      import.save!
      described_class.execute!(document: import, employee: employee)
    end

    expect(stock.reload.quantity).to eq(8)
    expect(import.reload.workflow_status_received?).to be true
    txn = StockTransaction.find_by(appoint_for_type: "StockImport", appoint_for_id: import.id)
    expect(txn).to be_present
    expect(txn).to be_add
    expect(txn).to be_import
    expect(txn.appoint_by).to eq(employee)
    expect(stock.available_count).to eq(8)
  end

  it "rejects an import with no lines" do
    empty_import = StockImport.new(
      company: company, warehouse: warehouse,
      category: stock.category, property_mapping: stock.property_mapping,
      code: "STKIM-EMPTY", business_type: :purchase, workflow_status: :pending
    )
    empty_import.save!

    expect {
      described_class.execute!(document: empty_import, employee: employee)
    }.to raise_error(StockMovementService::Error, /no stock lines/)
  end
end
