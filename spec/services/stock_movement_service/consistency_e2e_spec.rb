require 'rails_helper'

# Consistency E2E (docs/superpowers/specs/2026-09-23-stock-source-of-truth-design.md §8):
# every quantity mutation flows through StockTransaction's hardened callback —
# never direct SQL, never a background job.
RSpec.describe "Stock source-of-truth consistency", type: :model do
  let(:company) { create(:company) }
  let(:product) { create(:product, company: company) }
  let(:source_warehouse) { create(:warehouse, company: company) }
  let(:destination_warehouse) { create(:warehouse, company: company) }
  let!(:source_stock) do
    Stock.create!(company: company, warehouse: source_warehouse, product: product,
      quantity: 20, pending: 0, name: "E2E Source", code: "STK-E2S")
  end

  it "transfer: initiate reduces POS availability, receive moves quantity with two ledger rows" do
    transfer = StockTransfer.create!(
      company: company, warehouse: source_warehouse, destination_warehouse: destination_warehouse,
      category: source_stock.category, property_mapping: source_stock.property_mapping,
      code: "STKTR-E2E1", name: "E2E move", business_type: :transfer, workflow_status: :pending
    )
    transfer.stock_item_appointments.create!(company: company, stock: source_stock, quantity: 6)

    StockMovementService::Transfers::InitiateService.call(transfer: transfer, employee: nil)

    # POS reads availability from the counter — held units disappear immediately
    expect(source_stock.available_count).to eq(14)
    expect(source_stock.reload.quantity).to eq(20) # physical units untouched

    StockMovementService::Transfers::ReceiveService.call(transfer: transfer.reload, employee: nil)

    expect(source_stock.reload.quantity).to eq(14)
    expect(source_stock.pending).to eq(0)
    dest_stock = Stock.find_by!(company: company, warehouse: destination_warehouse, product: product)
    expect(dest_stock.quantity).to eq(6)
    expect(dest_stock.available_count).to eq(6)

    legs = StockTransaction.where(transaction_type: :transfer)
    expect(legs.count).to eq(2)
    expect(legs.map(&:direction)).to contain_exactly("add", "remove")
    # Conservation: units moved, never created or destroyed
    total = Stock.where(company: company, product: product).sum(:quantity)
    expect(total).to eq(20)
  end

  it "purchase: final workflow approval lands stock through the import chain" do
    category = Seed::CategoryService.find_or_create_for(company: company, resource_name: "purchases")
    Seed::WorkflowService.create(
      company: company, category: category, name: "E2E Purchase Process", process_type: :purchase_process
    ).tap do |workflow|
      [ { name: "Submit", position: 1 }, { name: "Approve", position: 2 } ].each do |attrs|
        Seed::WorkflowStepService.create(company: company, workflow: workflow, **attrs)
      end
    end
    owner = company.employees.find_by(business_type: "owner")
    purchase = create(:purchase, company: company, category: category, created_by_employee: owner)
    item = Seed::PurchaseItemService.create(company: company, product: product, name: "E2E item")
    purchase.purchase_item_appointments.create!(
      company: company, purchase_item: item, quantity: 7, unit_price: 1, total_price: 7
    )

    expect {
      Workflows::AdvanceService.call(subject: purchase, employee: owner, outcome: :approved)
      result = Workflows::AdvanceService.call(subject: purchase.reload, employee: owner, outcome: :approved)
      expect(result[:success]).to be true
    }.to change(StockTransaction.where(transaction_type: :import), :count).by(1)

    stock = Stock.find_by!(company: company, warehouse: purchase.reload.warehouse, product: product)
    expect(stock.quantity).to eq(7)
    expect(Stock.where(company: company, product: product).sum(:quantity)).to eq(27) # 20 held nowhere, 7 new
  end

  it "insufficient stock rolls back the whole movement (document + ledger + quantity)" do
    transfer = StockTransfer.create!(
      company: company, warehouse: source_warehouse, destination_warehouse: destination_warehouse,
      category: source_stock.category, property_mapping: source_stock.property_mapping,
      code: "STKTR-E2E2", name: "E2E fail", business_type: :transfer, workflow_status: :pending
    )
    transfer.stock_item_appointments.create!(company: company, stock: source_stock, quantity: 99)

    expect {
      StockMovementService::Transfers::InitiateService.call(transfer: transfer, employee: nil)
    }.to raise_error(StockMovementService::Error)

    expect(source_stock.reload.pending).to eq(0)
    expect(source_stock.available_count).to eq(20)
    expect(transfer.reload.workflow_status).to eq("pending")
  end
end
