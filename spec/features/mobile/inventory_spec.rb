# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Mobile Inventory", type: :feature, js: true do
  let(:company) { create(:company, business_type: :retail) }
  let(:user) { company.user }
  let(:branch) { create(:branch, company: company, name: "Grocery VN") }
  let!(:operation_record) { create(:operation, company: company, operation_type: :inventory, name: "Inventory Command") }
  let!(:warehouse) { Seed::WarehouseService.create(company: company, branch: branch, name: "Branch 1 Warehouse", code: "WH-01") }
  let(:product) { create(:product, company: company, name: "Product 1", code: "SKU-001", business_type: :physical) }

  def inventory_path(warehouse_id: warehouse.id)
    "/mobile/companies/#{company.id}/operations/inventory/#{operation_record.id}?warehouse_id=#{warehouse_id}"
  end

  def create_stock(quantity:)
    stock = Seed::StockService.create(
      company: company, warehouse: warehouse, branch: branch,
      product_id: product.id, name: product.name, code: product.code,
      quantity: quantity, pending: 0, discarded_at: nil
    )
    stock.update!(discarded_at: nil, property_string_1: "A-01")
    stock
  end

  before { sign_in(user) }

  scenario "loads the real inventory console in the mobile shell" do
    create_stock(quantity: 10)

    visit inventory_path

    within(find('[data-operation-block="kpis"]', wait: 10)) do
      expect(page).to have_content("STOCK ROWS")
      expect(page).to have_content("NEEDS ATTENTION")
      expect(page).to have_content("INBOUND OPEN")
      expect(page).to have_content("OUTBOUND OPEN")
    end
    within(find('[data-operation-block="ledger"]', wait: 10)) do
      expect(page).to have_content("Product 1")
      expect(page).to have_content("SKU-001")
      expect(page).to have_content("On hand, reserved, and available for Branch 1 Warehouse.")
    end
    within(find('[data-operation-block="inbound"]', wait: 10)) { expect(page).to have_content("Nothing waiting to receive.") }
    within(find('[data-operation-block="outbound"]', wait: 10)) { expect(page).to have_content("Nothing waiting to leave.") }
    within(find('[data-operation-block="last-count"]', wait: 10)) do
      expect(page).to have_content("No count recorded")
      expect(page).to have_content("1 rows in this warehouse.")
    end

    expect(page).to have_no_content("Store Overview")
    expect(page).to have_no_content("BOM")
    expect(page).to have_no_content("Zone Capacity")
    expect(page).to have_no_content("Cloud Sync")
    expect(page).to have_no_content("RFID")
  end

  scenario "opens inventory from the mobile operations list" do
    create_stock(quantity: 10)

    visit mobile_company_operations_path(company)
    click_link "Open Inventory"

    expect(page).to have_current_path(inventory_path, wait: 10)
    expect(page).to have_content("STOCK ROWS", wait: 10)
  end

  scenario "receives stock from the mobile drawer" do
    stock = create_stock(quantity: 10)

    visit inventory_path
    within(find('[data-operation-block="context"]', wait: 10)) { click_button "Receive" }

    within(find('[data-operation-block="drawer"]', wait: 10)) do
      find("[data-stock-id='#{stock.id}']", wait: 10).click
      fill_in "inventory-receipt-quantity", with: "5"
      click_button "Post receipt"
    end

    expect(page).to have_content("Received 5", wait: 10)
    expect(stock.reload.quantity).to eq(15)
  end

  scenario "stacks the ledger above the side panels on a phone in portrait" do
    create_stock(quantity: 10)
    page.driver.browser.manage.window.resize_to(390, 844)
    visit inventory_path

    expect(page).to have_content("STOCK ROWS", wait: 10)
    main = find("[data-inventory-main-column]")
    side = find("[data-inventory-side-column]")

    expect(side.native.rect.y).to be > main.native.rect.y
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end

  scenario "stacks the ledger above the side panels on a phone in landscape" do
    create_stock(quantity: 10)
    page.driver.browser.manage.window.resize_to(844, 390)
    visit inventory_path

    expect(page).to have_content("STOCK ROWS", wait: 10)
    main = find("[data-inventory-main-column]")
    side = find("[data-inventory-side-column]")

    expect(side.native.rect.y).to be > main.native.rect.y
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end

  scenario "stacks the ledger above the side panels on a tablet in portrait" do
    create_stock(quantity: 10)
    page.driver.browser.manage.window.resize_to(768, 1024)
    visit inventory_path

    expect(page).to have_content("STOCK ROWS", wait: 10)
    main = find("[data-inventory-main-column]")
    side = find("[data-inventory-side-column]")

    expect(side.native.rect.y).to be > main.native.rect.y
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end

  scenario "shows the ledger beside the side panels on a landscape tablet" do
    create_stock(quantity: 10)
    page.driver.browser.manage.window.resize_to(1280, 800)
    visit inventory_path

    expect(page).to have_content("STOCK ROWS", wait: 10)
    main = find("[data-inventory-main-column]")
    side = find("[data-inventory-side-column]")

    expect(side.native.rect.x).to be > main.native.rect.x
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end
end
