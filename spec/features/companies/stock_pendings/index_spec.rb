# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::StockPendings index", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:warehouse) { create(:warehouse, company: company, name: "Hold Warehouse") }
  let(:product) { create(:product, company: company, name: "Hold Widget #{SecureRandom.hex(4)}") }
  let!(:stock) do
    Seed::StockService.create(
      company: company, warehouse: warehouse,
      branch: warehouse.branch, product_id: product.id, quantity: 20
    )
  end

  before do
    sign_in(owner)
    page.execute_script("localStorage.clear()")
    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
      "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
      "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
      "branches" => [],
      "departments" => [],
      "roles" => []
    )
    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])",
      { user: JSON.parse(owner.to_json), companies: [ company_data ], enums: {}, employees: [] }.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")

    StockPendings::HoldService.call(
      company: company, warehouse: warehouse, stock: stock,
      quantity: 4, business_type: :manual, name: "Cycle Count Hold"
    )
  end

  scenario "index page loads and displays the pendings table" do
    visit "/companies/#{company.id}/stock_pendings"

    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_selector("th", text: "Quantity")
    expect(page).to have_selector("th", text: "Status")
    expect(page).to have_selector("th", text: "Warehouse")
    expect(page).to have_content("Cycle Count Hold")
    expect(page).to have_content("Hold Warehouse")
  end

  scenario "status filter narrows to released rows" do
    StockPendings::ReleaseService.call(
      company: company, warehouse: warehouse, stock: stock, quantity: 4
    )
    StockPendings::HoldService.call(
      company: company, warehouse: warehouse, stock: stock,
      quantity: 2, business_type: :event, name: "Second Hold"
    )

    visit "/companies/#{company.id}/stock_pendings?workflow_status=completed"

    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_content("Cycle Count Hold")
    expect(page).to have_no_content("Second Hold")
  end
end
