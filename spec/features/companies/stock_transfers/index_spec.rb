require "rails_helper"

RSpec.feature "Companies::StockTransfers Management", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }

  let(:warehouse_from) do
    Seed::WarehouseService.create(
      company: company,
      branch: branch,
      name: "Main Warehouse"
    )
  end

  let(:warehouse_to) do
    Seed::WarehouseService.create(
      company: company,
      branch: branch,
      name: "Secondary Warehouse"
    )
  end

  let(:product) do
    Seed::ProductService.create(
      company: company,
      name: "Test Product"
    )
  end

  let!(:transfer1) do
    Seed::StockTransferService.create(
      company: company,
      product: product,
      branch: branch,
      appoint_from: warehouse_from,
      appoint_to: warehouse_to,
      code: "TRF001",
      quantity: 50,
      business_type: "transfer",
      workflow_status: "confirmed"
    )
  end

  let!(:transfer2) do
    t = Seed::StockTransferService.create(
      company: company,
      product: product,
      branch: branch,
      appoint_from: warehouse_to,
      appoint_to: warehouse_from,
      code: "TRF002",
      quantity: 25,
      business_type: "adjustment",
      workflow_status: "pending"
    )
    t
  end

  before do
    sign_in(owner)
  end

  scenario "index page loads and displays stock transfers table" do
    visit company_stock_transfers_path(company)

    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('th', text: 'Code')
    expect(page).to have_selector('th', text: 'Product')
    expect(page).to have_selector('th', text: 'From')
    expect(page).to have_selector('th', text: 'To')
    expect(page).to have_selector('th', text: 'Quantity')
    expect(page).to have_selector('th', text: 'Type')
    expect(page).to have_selector('th', text: 'Status')

    expect(page).to have_selector('tbody tr')
  end

  scenario "display stock transfer data in table" do
    visit company_stock_transfers_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_content("TRF001")
    expect(page).to have_content("Test Product")
    expect(page).to have_content("Main Warehouse")
    expect(page).to have_content("Secondary Warehouse")
    expect(page).to have_content(50)
  end

  scenario "display business type as badge" do
    visit company_stock_transfers_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_content("Transfer")
    expect(page).to have_content("Adjustment")
  end

  scenario "display workflow status as badge" do
    visit company_stock_transfers_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('span.rounded-full', wait: 10)
  end

  scenario "search by code filters results" do
    visit company_stock_transfers_path(company)
    expect(page).to have_selector('table', wait: 10)

    find('input[name="search"]').fill_in(with: 'TRF001')
    click_button "Search"

    expect(page).to have_current_path(/search=TRF001/)
    expect(page).to have_selector('tbody tr', wait: 10)
    expect(page).to have_content("TRF001")
    expect(page).not_to have_content("TRF002")
  end

  scenario "filter by business type updates URL and filters table" do
    visit company_stock_transfers_path(company)
    expect(page).to have_selector('table', wait: 10)

    select("Adjustment", from: 'business_type')
    click_button "Search"

    expect(page).to have_current_path(/business_type=adjustment/)
    expect(page).to have_selector('tbody tr', wait: 10)
    expect(page).to have_content("Adjustment")
  end

  scenario "filter by workflow status updates URL and filters table" do
    visit company_stock_transfers_path(company)
    expect(page).to have_selector('table', wait: 10)

    select("Pending", from: 'workflow_status')
    click_button "Search"

    expect(page).to have_current_path(/workflow_status=pending/)
    expect(page).to have_selector('tbody tr', wait: 10)
  end

  scenario "clear filters and search" do
    visit company_stock_transfers_path(company, search: "TRF001", business_type: "transfer")
    expect(page).to have_selector('table', wait: 10)

    find('input[name="search"]').fill_in(with: '')
    select("All Types", from: 'business_type')
    click_button "Search"

    expect(page).to have_current_path(/search=/)
  end
end
