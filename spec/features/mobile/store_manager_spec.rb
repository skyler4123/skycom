# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Mobile Store Manager", type: :feature, js: true do
  let(:company) { create(:company, business_type: :retail) }
  let(:user) { company.user }
  let(:branch) { create(:branch, company: company, name: "Downtown Flagship") }
  let!(:operation_record) do
    create(:operation, company: company, branch: branch, name: "Store Command", operation_type: :store_manager)
  end
  let(:store_manager_path) do
    "/mobile/companies/#{company.id}/operations/store_manager/#{operation_record.id}?branch_id=#{branch.id}"
  end
  let!(:employee) do
    create(:employee, company: company, branch: branch, name: "Marcus Sterling").tap do |record|
      record.update!(lifecycle_status: :active, discarded_at: nil)
    end
  end
  let(:customer) { Seed::CustomerService.create(company: company, branch: branch, name: "Marcus Vance") }
  let(:product) { create(:product, company: company, name: "MX Master 3S Graphite") }
  let(:warehouse) { Seed::WarehouseService.create(company: company, branch: branch, name: "WH-01 Central") }

  before do
    create_order(workflow_status: :paid, business_type: :in_store, customer: customer)
    create_order(workflow_status: :pending, business_type: :online, customer: customer)
    create_low_stock
    sign_in(user)
  end

  def create_order(workflow_status:, business_type:, customer:, quantity: 2, unit_price: 50.0)
    order = Seed::OrderService.create(
      company: company,
      branch: branch,
      customer: customer,
      currency: :usd,
      name: "Store order #{SecureRandom.hex(4)}",
      workflow_status: workflow_status,
      business_type: business_type
    )
    Seed::OrderProductAppointmentService.create(
      company: company,
      order: order,
      product: product,
      quantity: quantity,
      unit_price: unit_price
    )
    order
  end

  def create_low_stock(quantity: 2)
    stock = Seed::StockService.create(
      company: company,
      warehouse: warehouse,
      branch: branch,
      product_id: product.id,
      name: "MX Master 3S Graphite",
      code: "LOGI-MX3S-GRP",
      quantity: quantity,
      pending: 0,
      discarded_at: nil
    )
    stock.update!(discarded_at: nil)
    stock
  end

  scenario "loads the live store console in the mobile shell" do
    visit store_manager_path
    expect(page).to have_content("Store Fulfillment & Customer Orders Queue", wait: 10)
    expect(page).to have_content("GROSS SALES TODAY")
    expect(page).to have_content("Marcus Vance")
    expect(page).to have_content("MX Master 3S Graphite")
    expect(page).to have_content("Shelf Replenishment Requisitions")
    expect(page).to have_content("On-Duty Shift Roster")
  end

  scenario "opens the store manager from the mobile operations list" do
    visit mobile_company_operations_path(company)

    click_link "Open Store Manager"

    expect(page).to have_current_path(store_manager_path, wait: 10)
    expect(page).to have_content("Store Fulfillment & Customer Orders Queue", wait: 10)
  end

  scenario "stacks the command panels under the queue on a phone in portrait" do
    page.driver.browser.manage.window.resize_to(390, 844)
    visit store_manager_path

    expect(page).to have_content("Store Fulfillment & Customer Orders Queue", wait: 10)
    main = find("[data-store-manager-main-column]")
    side = find("[data-store-manager-side-column]")

    expect(side.native.rect.y).to be > main.native.rect.y
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end

  scenario "stacks the command panels under the queue on a phone in landscape" do
    page.driver.browser.manage.window.resize_to(844, 390)
    visit store_manager_path

    expect(page).to have_content("Store Fulfillment & Customer Orders Queue", wait: 10)
    main = find("[data-store-manager-main-column]")
    side = find("[data-store-manager-side-column]")

    expect(side.native.rect.y).to be > main.native.rect.y
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end

  scenario "stacks the command panels under the queue on a tablet in portrait" do
    page.driver.browser.manage.window.resize_to(768, 1024)
    visit store_manager_path

    expect(page).to have_content("Store Fulfillment & Customer Orders Queue", wait: 10)
    main = find("[data-store-manager-main-column]")
    side = find("[data-store-manager-side-column]")

    expect(side.native.rect.y).to be > main.native.rect.y
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end

  scenario "shows the command panels beside the queue on a landscape tablet" do
    page.driver.browser.manage.window.resize_to(1280, 800)
    visit store_manager_path

    expect(page).to have_content("Store Fulfillment & Customer Orders Queue", wait: 10)
    main = find("[data-store-manager-main-column]")
    side = find("[data-store-manager-side-column]")

    expect(side.native.rect.x).to be > main.native.rect.x
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end
end
