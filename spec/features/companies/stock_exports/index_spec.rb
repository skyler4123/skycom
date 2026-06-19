require "rails_helper"

RSpec.feature "Companies::StockExports Management", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }

  let(:warehouse) do
    Seed::WarehouseService.create(
      company: company,
      branch: branch,
      name: "Test Warehouse"
    )
  end

  let(:product) do
    Seed::ProductService.create(
      company: company,
      name: "Test Product"
    )
  end

  let!(:export1) do
    Seed::StockExportService.create(
      company: company,
      warehouse: warehouse,
      product: product,
      branch: branch,
      code: "STKEX001",
      quantity: 50,
      business_type: "sale",
      workflow_status: "completed"
    )
  end

  let!(:export2) do
    Seed::StockExportService.create(
      company: company,
      warehouse: warehouse,
      product: product,
      branch: branch,
      code: "STKEX002",
      quantity: 25,
      business_type: "damaged",
      workflow_status: "pending"
    )
  end

  before do
    sign_in(owner)
  end

  scenario "index page loads and displays stock exports table" do
    visit company_stock_exports_path(company)

    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('th', text: 'Code')
    expect(page).to have_selector('th', text: 'Product')
    expect(page).to have_selector('th', text: 'Category')
    expect(page).to have_selector('th', text: 'From')
    expect(page).to have_selector('th', text: 'To')
    expect(page).to have_selector('th', text: 'Quantity')
    expect(page).to have_selector('th', text: 'Type')
    expect(page).to have_selector('th', text: 'Status')

    expect(page).to have_selector('tbody tr')
  end

  scenario "display stock export data in table" do
    visit company_stock_exports_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_content("STKEX001")
    expect(page).to have_content("Test Product")
    expect(page).to have_content(50)
  end

  scenario "display business type as badge" do
    visit company_stock_exports_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_content("Sale")
    expect(page).to have_content("Damaged")
  end

  scenario "display workflow status as badge" do
    visit company_stock_exports_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('span.rounded-full', wait: 10)
  end
end
