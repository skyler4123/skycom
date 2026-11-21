# frozen_string_literal: true

require "rails_helper"

RSpec.describe StoreManager::ReplenishmentService, type: :service do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:employee) { create(:employee, company: company, branch: branch) }
  let(:warehouse) { create(:warehouse, company: company, branch: branch, name: "Branch Warehouse") }
  let(:source_warehouse) { create(:warehouse, company: company, branch: branch, name: "Central Warehouse") }
  let(:product) { create(:product, company: company, name: "MX Master 3S", code: "LOGI-MX3S") }

  it "creates one transfer from the supplying warehouse and reuses it" do
    stock = create_store_stock(company: company, branch: branch, warehouse: warehouse, product: product,
      quantity: 2, code: "LOGI-MX3S")
    create_store_stock(company: company, branch: branch, warehouse: source_warehouse, product: product,
      quantity: 10, code: "LOGI-MX3S-CENTRAL")

    first = described_class.call(
      company: company, branch: branch, employee: employee, stock_id: stock.id
    )
    second = described_class.call(
      company: company, branch: branch, employee: employee, stock_id: stock.id
    )

    expect(first[:document]).to include(type: "transfer")
    expect(first[:message]).to include("Transfer")
    expect(second[:existing]).to be(true)
    expect(company.stock_transfers.count).to eq(1)
    transfer = company.stock_transfers.first
    expect(transfer.quantity).to eq(8)
    expect(transfer.destination_warehouse_id).to eq(warehouse.id)
    expect(transfer.warehouse_id).to eq(source_warehouse.id)
  end

  it "creates one purchase draft when the warehouse has no stock" do
    supplier = create(:supplier, company: company)
    product.update!(default_supplier: supplier)
    stock = create_store_stock(company: company, branch: branch, warehouse: warehouse, product: product,
      quantity: 2, code: "LOGI-MX3S")

    first = described_class.call(
      company: company, branch: branch, employee: employee, stock_id: stock.id
    )
    second = described_class.call(
      company: company, branch: branch, employee: employee, stock_id: stock.id
    )

    expect(first[:document]).to include(type: "purchase")
    expect(second[:existing]).to be(true)
    expect(company.purchases.count).to eq(1)
    purchase = company.purchases.first
    expect(purchase.business_type).to eq("stock_reorder")
    expect(purchase.purchase_purchase_item_appointments.first.quantity).to eq(8)
  end

  it "rejects an item that is not below its reorder point" do
    stock = create_store_stock(company: company, branch: branch, warehouse: warehouse, product: product,
      quantity: 50, code: "LOGI-MX3S")

    expect {
      described_class.call(company: company, branch: branch, employee: employee, stock_id: stock.id)
    }.to raise_error(StoreManager::Error, "This item is not below its reorder point.")
  end
end
