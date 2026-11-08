# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::Operations::Inventory", type: :feature, js: true do
  let(:company_user) { create(:user, :company_owner) }
  let(:company) { Seed::CompanyService.new(user: company_user, country: :us, business_type: :retail).tap(&:save!) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company, name: "Central Distribution Hub", code: "WH-01") }
  let(:warehouse) { Seed::WarehouseService.create(company: company, branch: branch, name: "WH-01 Central") }
  let(:operation) { create(:operation, company: company, operation_type: :inventory) }
  let(:inventory_path) { "/companies/#{company.id}/operations/inventory/#{operation.id}?warehouse_id=#{warehouse.id}" }
  let(:product) { create(:product, company: company, name: "Micro-Controller PCB v2.4") }

  before do
    warehouse
    create(:operation_warehouse_appointment, company: company, operation: operation, warehouse: warehouse)
    stock = Seed::StockService.create(
      company: company,
      warehouse: warehouse,
      branch: branch,
      product_id: product.id,
      name: "Micro-Controller PCB v2.4",
      code: "SKU-ELEC-9021",
      quantity: 18,
      pending: 12,
      discarded_at: nil
    )
    stock.update!(discarded_at: nil)
    Seed::StockImportService.create(
      company: company,
      branch: branch,
      warehouse: warehouse,
      product: product,
      code: "IMP-TEST-001",
      quantity: 120,
      workflow_status: :in_progress,
      discarded_at: nil
    )
    Seed::StockExportService.create(
      company: company,
      branch: branch,
      warehouse: warehouse,
      product: product,
      code: "EXP-TEST-001",
      quantity: 40,
      workflow_status: :confirmed,
      discarded_at: nil
    )
    sign_in(owner)
  end

  scenario "loads the live stock ledger, dock activity and capacity panels" do
    visit inventory_path

    expect(page).to have_content("Stock Ledger & Granular Bin Registry", wait: 10)
    expect(page).to have_content("Micro-Controller PCB v2.4")
    expect(page).to have_content("SKU-ELEC-9021")
    expect(page).to have_content("Active Freight Docks")
    expect(page).to have_content("Zone Capacity Map")
    expect(page).to have_content("Audit & RFID Integrity")
    expect(page).to have_content("TOTAL SKUS ACTIVE")
  end

  scenario "filters stock ledger rows by search" do
    visit inventory_path
    expect(page).to have_content("Micro-Controller PCB v2.4", wait: 10)

    fill_in "inventory-stock-search", with: "Nothing matches"

    expect(page).to have_content("No stock rows match this view.", wait: 5)
  end
end
