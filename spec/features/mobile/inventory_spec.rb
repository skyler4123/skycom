# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Mobile Inventory", type: :feature, js: true do
  let(:company) { create(:company, business_type: :retail) }
  let(:user) { company.user }
  let(:branch) { create(:branch, company: company, name: "Central Distribution Hub", code: "WH-01") }
  let(:warehouse) { Seed::WarehouseService.create(company: company, branch: branch, name: "WH-01 Central") }
  let(:operation_record) do
    create(:operation, company: company, operation_type: :inventory, name: "Inventory Command")
  end
  let(:inventory_path) do
    "/mobile/companies/#{company.id}/operations/inventory/#{operation_record.id}?warehouse_id=#{warehouse.id}"
  end
  let(:product) { create(:product, company: company, name: "Micro-Controller PCB v2.4") }

  before do
    warehouse
    create(:operation_warehouse_appointment, company: company, operation: operation_record, warehouse: warehouse)
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
    sign_in(user)
  end

  scenario "loads the live stock console in the mobile shell" do
    visit inventory_path

    expect(page).to have_content("Stock Ledger & Granular Bin Registry", wait: 10)
    expect(page).to have_content("Micro-Controller PCB v2.4")
    expect(page).to have_content("SKU-ELEC-9021")
    expect(page).to have_content("Active Freight Docks")
    expect(page).to have_content("Zone Capacity Map")
    expect(page).to have_content("Audit & RFID Integrity")
  end

  scenario "opens inventory from the mobile operations list" do
    visit mobile_company_operations_path(company)

    click_link "Open Inventory"

    expect(page).to have_current_path(inventory_path, wait: 10)
    expect(page).to have_content("Stock Ledger & Granular Bin Registry", wait: 10)
  end

  scenario "stacks the ledger above the dock panels on a phone in portrait" do
    page.driver.browser.manage.window.resize_to(390, 844)
    visit inventory_path

    expect(page).to have_content("Stock Ledger & Granular Bin Registry", wait: 10)
    main = find("[data-inventory-main-column]")
    side = find("[data-inventory-side-column]")

    expect(side.native.rect.y).to be > main.native.rect.y
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end

  scenario "stacks the ledger above the dock panels on a phone in landscape" do
    page.driver.browser.manage.window.resize_to(844, 390)
    visit inventory_path

    expect(page).to have_content("Stock Ledger & Granular Bin Registry", wait: 10)
    main = find("[data-inventory-main-column]")
    side = find("[data-inventory-side-column]")

    expect(side.native.rect.y).to be > main.native.rect.y
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end

  scenario "stacks the ledger above the dock panels on a tablet in portrait" do
    page.driver.browser.manage.window.resize_to(768, 1024)
    visit inventory_path

    expect(page).to have_content("Stock Ledger & Granular Bin Registry", wait: 10)
    main = find("[data-inventory-main-column]")
    side = find("[data-inventory-side-column]")

    expect(side.native.rect.y).to be > main.native.rect.y
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end

  scenario "shows the ledger beside the dock panels on a landscape tablet" do
    page.driver.browser.manage.window.resize_to(1280, 800)
    visit inventory_path

    expect(page).to have_content("Stock Ledger & Granular Bin Registry", wait: 10)
    main = find("[data-inventory-main-column]")
    side = find("[data-inventory-side-column]")

    expect(side.native.rect.x).to be > main.native.rect.x
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end
end
