# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Mobile Store Manager", type: :feature, js: true do
  let(:company) { create(:company, business_type: :retail) }
  let(:user) { company.user }
  let(:owner_employee) { company.employees.find_by!(user: user) }
  let(:branch) { create(:branch, company: company, name: "Branch 1") }
  let!(:operation_record) do
    create(:operation, company: company, branch: branch, name: "Store Command", operation_type: :store_manager)
  end
  let(:store_manager_path) do
    "/mobile/companies/#{company.id}/operations/store_manager/#{operation_record.id}?branch_id=#{branch.id}"
  end
  let!(:employee) do
    create(:employee, company: company, branch: branch, name: "Lekisha Dare").tap do |record|
      record.update!(lifecycle_status: :active, discarded_at: nil)
    end
  end
  let(:warehouse) { Seed::WarehouseService.create(company: company, branch: branch, name: "Branch 1 Warehouse") }
  let(:product) { create(:product, company: company, name: "MX Master 3S", code: "LOGI-MX3S") }

  before do
    paid, = create_store_invoice_order(
      company: company, branch: branch, employee: owner_employee,
      total_cents: 10_000, tender: :cash
    )
    @open_order = create(
      :order, company: company, branch: branch,
      customer: create(:customer, company: company, branch: branch),
      name: "Open Mobile Order #{SecureRandom.hex(4)}",
      workflow_status: :pending, fulfillment_channel: :click_collect
    )
    @open_order.update_columns(discarded_at: nil)
    create_store_stock(company: company, branch: branch, warehouse: warehouse, product: product,
      quantity: 2, code: "LOGI-MX3S")
    sign_in(user)
  end

  scenario "loads the live store console in the mobile shell" do
    visit store_manager_path
    expect(page).to have_content("Store overview", wait: 10)
    expect(page).to have_content(/Gross sales/i)
    expect(page).to have_content("Fulfillment queue")
    expect(page).to have_content("Shelf replenishment")
    expect(page).to have_content("On-duty roster")
    expect(page).to have_content("No door sensor")
  end

  scenario "opens the store manager from the mobile operations list" do
    visit mobile_company_operations_path(company)

    click_link "Open Store Manager"

    expect(page).to have_current_path(store_manager_path, wait: 10)
    expect(page).to have_content("Store overview", wait: 10)
  end

  scenario "marks an order ready from the mobile console" do
    visit store_manager_path

    within("[data-order-code='#{@open_order.code}']") { click_button "Mark ready" }

    expect(page).to have_content("ready for handover", wait: 10)
    expect(@open_order.reload.fulfillment_status).to eq("ready")
  end

  scenario "stacks the command panels under the queue on a phone in portrait" do
    page.driver.browser.manage.window.resize_to(390, 844)
    visit store_manager_path

    expect(page).to have_content("Store overview", wait: 10)
    main = find("[data-store-manager-main-column]")
    side = find("[data-store-manager-side-column]")

    expect(side.native.rect.y).to be > main.native.rect.y
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end

  scenario "stacks the command panels under the queue on a phone in landscape" do
    page.driver.browser.manage.window.resize_to(844, 390)
    visit store_manager_path

    expect(page).to have_content("Store overview", wait: 10)
    main = find("[data-store-manager-main-column]")
    side = find("[data-store-manager-side-column]")

    expect(side.native.rect.y).to be > main.native.rect.y
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end

  scenario "stacks the command panels under the queue on a tablet in portrait" do
    page.driver.browser.manage.window.resize_to(768, 1024)
    visit store_manager_path

    expect(page).to have_content("Store overview", wait: 10)
    main = find("[data-store-manager-main-column]")
    side = find("[data-store-manager-side-column]")

    expect(side.native.rect.y).to be > main.native.rect.y
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end

  scenario "shows the command panels beside the queue on a landscape tablet" do
    page.driver.browser.manage.window.resize_to(1280, 800)
    visit store_manager_path

    expect(page).to have_content("Store overview", wait: 10)
    main = find("[data-store-manager-main-column]")
    side = find("[data-store-manager-side-column]")

    expect(side.native.rect.x).to be > main.native.rect.x
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end
end
