require "rails_helper"

RSpec.feature "Companies::StockImports Management", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }

  let(:product) do
    Seed::ProductService.create(
      company: company,
      name: "Test Product"
    )
  end

  let!(:import1) do
    Seed::StockImportService.create(
      company: company,
      product: product,
      branch: branch,
      code: "STKIM001",
      quantity: 50,
      business_type: "purchase",
      workflow_status: "completed"
    )
  end

  let!(:import2) do
    Seed::StockImportService.create(
      company: company,
      product: product,
      branch: branch,
      code: "STKIM002",
      quantity: 25,
      business_type: "return",
      workflow_status: "pending"
    )
  end

  before do
    sign_in(owner)
  end

  scenario "index page loads and displays stock imports table" do
    visit company_stock_imports_path(company)

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

  scenario "display stock import data in table" do
    visit company_stock_imports_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_content("STKIM001")
    expect(page).to have_content("Test Product")
    expect(page).to have_content(50)
  end

  scenario "display business type as badge" do
    visit company_stock_imports_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_content("Purchase")
    expect(page).to have_content("Return")
  end

  scenario "display workflow status as badge" do
    visit company_stock_imports_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('span.rounded-full', wait: 10)
  end

  scenario "search by code filters results" do
    visit company_stock_imports_path(company)
    expect(page).to have_selector('table', wait: 10)

    find('input[name="search"]').fill_in(with: 'STKIM001')
    click_button "Search"

    expect(page).to have_current_path(/search=STKIM001/)
    expect(page).to have_selector('tbody tr', wait: 10)
    expect(page).to have_content("STKIM001")
    expect(page).not_to have_content("STKIM002")
  end

  scenario "filter by business type updates URL and filters table" do
    visit company_stock_imports_path(company)
    expect(page).to have_selector('table', wait: 10)

    select("Return", from: 'business_type')
    click_button "Search"

    expect(page).to have_current_path(/business_type=return/)
    expect(page).to have_selector('tbody tr', wait: 10)
    expect(page).to have_content("Return")
  end

  scenario "filter by workflow status updates URL and filters table" do
    visit company_stock_imports_path(company)
    expect(page).to have_selector('table', wait: 10)

    select("Pending", from: 'workflow_status')
    click_button "Search"

    expect(page).to have_current_path(/workflow_status=pending/)
    expect(page).to have_selector('tbody tr', wait: 10)
  end

  scenario "clear filters and search" do
    visit company_stock_imports_path(company, search: "STKIM001", business_type: "purchase")
    expect(page).to have_selector('table', wait: 10)

    find('input[name="search"]').fill_in(with: '')
    select("All Types", from: 'business_type')
    click_button "Search"

    expect(page).to have_current_path(/search=/)
  end
end
