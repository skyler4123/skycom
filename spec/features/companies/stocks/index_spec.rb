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
end
