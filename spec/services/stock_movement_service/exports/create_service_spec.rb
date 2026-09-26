require 'rails_helper'

RSpec.describe StockMovementService::Exports::CreateService, type: :model do
  let(:company) { create(:company) }
  let(:product) { create(:product, company: company) }
  let(:warehouse) { create(:warehouse, company: company) }
  let!(:stock) do
    Stock.create!(company: company, warehouse: warehouse, product: product, quantity: 10, pending: 4, name: "Exp Stock", code: "STK-EXP")
  end
  let(:employee) { create(:employee, company: company) }

  def build_export(quantity:, stock_ref: stock)
    export = StockExport.new(
      company: company, warehouse: warehouse,
      category: stock_ref.category, property_mapping: stock_ref.property_mapping,
      code: "STKEX-#{SecureRandom.hex(4).upcase}", name: "Write-off",
      business_type: :damaged, workflow_status: :pending
    )
    export.stock_item_appointments.build(company: company, stock: stock_ref, quantity: quantity)
    export
  end

  it "removes available (not pending) stock and marks the export shipped" do
    export = build_export(quantity: 6) # available = 10 - 4 = 6

    ActiveRecord::Base.transaction do
      export.save!
      described_class.execute!(document: export, employee: employee)
    end

    expect(stock.reload.quantity).to eq(4)
    expect(stock.reload.pending).to eq(4) # hold untouched
    expect(export.reload.workflow_status_shipped?).to be true
  end

  it "rolls back everything when a line exceeds available stock" do
    export = build_export(quantity: 7) # only 6 available

    expect {
      ActiveRecord::Base.transaction do
        export.save!
        described_class.execute!(document: export, employee: employee)
      end
    }.to raise_error(StockMovementService::Error, /Insufficient stock: available 6/)

    expect(StockExport.count).to eq(0)
    expect(StockItemAppointment.count).to eq(0)
    expect(StockTransaction.count).to eq(0)
    expect(stock.reload.quantity).to eq(10)
  end
end
