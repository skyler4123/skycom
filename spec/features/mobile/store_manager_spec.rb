# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Mobile Store Manager", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:user) { company.user }
  let(:branch) { create(:branch, company: company, name: "Downtown Branch") }
  let(:warehouse) { create(:warehouse, company: company, branch: branch, name: "Central Distribution Hub") }
  let!(:operation_record) do
    create(:operation, company: company, branch: branch, name: "Store Desk", operation_type: :store_manager)
  end
  let(:product) { create(:product, company: company, name: "Micro-Controller PCB v2.4") }
  let(:store_manager_path) do
    "/mobile/companies/#{company.id}/operations/store_manager/#{operation_record.id}?branch_id=#{branch.id}"
  end

  let!(:stock) do
    Stock.create!(
      company: company,
      branch: branch,
      warehouse: warehouse,
      product: product,
      quantity: 5,
      pending: 0,
      name: "Micro-Controller PCB v2.4",
      code: "SKU-ELEC-9021",
      business_type: :inventory,
      lifecycle_status: :active,
      workflow_status: :confirmed
    )
  end

  let!(:inbound) do
    StockImport.create!(
      company: company,
      branch: branch,
      warehouse: warehouse,
      product: product,
      quantity: 40,
      name: "Apex Silicon Ltd",
      code: "STKIM-MOBILE",
      business_type: :purchase,
      lifecycle_status: :active,
      workflow_status: :confirmed
    )
  end

  let!(:outbound) do
    StockExport.create!(
      company: company,
      branch: branch,
      warehouse: warehouse,
      product: product,
      quantity: 12,
      name: "Regional Retail Hub #04",
      code: "STKEX-MOBILE",
      business_type: :sale,
      lifecycle_status: :active,
      workflow_status: :confirmed
    )
  end

  before { sign_in(user) }

  scenario "loads the store manager console in the mobile shell" do
    visit store_manager_path

    expect(page).to have_content("Store Manager Console", wait: 10)
    expect(page).to have_content("Downtown Branch")
    expect(page).to have_content("On-Hand Stock")
    expect(page).to have_content("Micro-Controller PCB v2.4")
    expect(page).to have_content("Apex Silicon Ltd")
    expect(page).to have_content("Regional Retail Hub #04")
  end

  scenario "opens store manager from the mobile operations list" do
    visit mobile_company_operations_path(company)

    click_link "Open Store Manager"

    expect(page).to have_current_path(store_manager_path, wait: 10)
    expect(page).to have_content("Store Manager Console", wait: 10)
  end

  scenario "stacks the document panels under the stock directory in portrait" do
    page.driver.browser.manage.window.resize_to(768, 1024)
    visit store_manager_path

    expect(page).to have_content("Store Manager Console", wait: 10)
    stock_section = find("section", text: /On-Hand Stock/i)
    panels = find("aside")

    expect(panels.native.rect.y).to be > stock_section.native.rect.y
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end

  scenario "shows the document panels beside the stock directory on a landscape tablet" do
    page.driver.browser.manage.window.resize_to(1280, 800)
    visit store_manager_path

    expect(page).to have_content("Store Manager Console", wait: 10)
    stock_section = find("section", text: /On-Hand Stock/i)
    panels = find("aside")

    expect(panels.native.rect.x).to be > stock_section.native.rect.x
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end

  scenario "renders the console on a phone in portrait" do
    page.driver.browser.manage.window.resize_to(390, 844)
    visit store_manager_path

    expect(page).to have_content("Store Manager Console", wait: 10)
    expect(page).to have_content("Micro-Controller PCB v2.4")
    expect(page).to have_content("Apex Silicon Ltd")
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end
end
