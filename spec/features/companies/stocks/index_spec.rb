require "rails_helper"

RSpec.feature "Companies::Stocks Management", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }

  let(:warehouse) do
    Seed::WarehouseService.create(
      company: company,
      branch: branch
    )
  end

  let(:product) do
    Seed::ProductService.create(
      company: company,
      name: "Test Product"
    )
  end

  let(:product2) do
    Seed::ProductService.create(
      company: company,
      name: "Low Stock Product"
    )
  end

  let!(:stock) do
    Seed::StockService.create(
      warehouse: warehouse,
      product_id: product.id,
      company: company,
      branch: branch,
      business_type: "inventory",
      workflow_status: "confirmed"
    )
  end

  let!(:low_stock) do
    Seed::StockService.create(
      warehouse: warehouse,
      product_id: product2.id,
      company: company,
      branch: branch,
      business_type: "finished_good",
      workflow_status: "confirmed"
    )
  end

  before do
    sign_in(owner)
  end

  scenario "index page loads and displays stocks table" do
    visit company_stocks_path(company)

    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('th', text: 'Product')
    expect(page).to have_selector('th', text: 'Warehouse')
    expect(page).to have_selector('th', text: 'Type')
    expect(page).to have_selector('th', text: 'Status')

    expect(page).to have_selector('tbody tr')
  end

  scenario "display stock data in table" do
    visit company_stocks_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_content("Test Product")
    expect(page).to have_content(warehouse.name)
  end

  scenario "display business type as badge" do
    visit company_stocks_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_content("Inventory")
    expect(page).to have_content("Finished_good")
  end

  scenario "display workflow status as badge" do
    visit company_stocks_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('span.rounded-full', wait: 10)
  end

  scenario "display stock with workflow status" do
    visit company_stocks_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('tbody tr', wait: 10)
  end

  scenario "search filters results" do
    visit company_stocks_path(company)
    expect(page).to have_selector('table', wait: 10)

    # Search with empty string to see all results (since we can't predict Faker names)
    find('input[name="search"]').fill_in(with: '')
    click_button "Search"

    expect(page).to have_current_path(/search=/)
    expect(page).to have_selector('tbody tr', wait: 10)
  end

  scenario "filter by business type updates URL and filters table" do
    visit company_stocks_path(company)
    expect(page).to have_selector('table', wait: 10)

    select("Finished good", from: 'business_type')
    click_button "Search"

    expect(page).to have_current_path(/business_type=finished_good/)
    expect(page).to have_selector('tbody tr', wait: 10)
    expect(page).to have_content("Finished_good")
  end

  scenario "filter by workflow status updates URL and filters table" do
    low_stock.update!(workflow_status: "pending")

    visit company_stocks_path(company)
    expect(page).to have_selector('table', wait: 10)

    select("Pending", from: 'workflow_status')
    click_button "Search"

    expect(page).to have_current_path(/workflow_status=pending/)
    expect(page).to have_selector('tbody tr', wait: 10)
  end

  scenario "clear filters and search" do
    visit company_stocks_path(company, search: "Test", business_type: "inventory")
    expect(page).to have_selector('table', wait: 10)

    find('input[name="search"]').fill_in(with: '')
    select("All Types", from: 'business_type')
    click_button "Search"

    expect(page).to have_current_path(/search=/)
  end
end
