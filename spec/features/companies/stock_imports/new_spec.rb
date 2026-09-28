# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::StockImports New", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let!(:warehouse) { create(:warehouse, company: company, name: "Main") }
  let!(:product_a) { create(:product, company: company, name: "Gadget #{SecureRandom.hex(4)}") }
  let!(:product_b) { create(:product, company: company, name: "Widget #{SecureRandom.hex(4)}") }
  let!(:stock_a) do
    Stock.create!(company: company, warehouse: warehouse, product: product_a,
      quantity: 10, name: "Imp-A", code: "STK-IMPA-#{SecureRandom.hex(3).upcase}")
  end
  let!(:stock_b) do
    Stock.create!(company: company, warehouse: warehouse, product: product_b,
      quantity: 10, name: "Imp-B", code: "STK-IMPB-#{SecureRandom.hex(3).upcase}")
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
  end

  scenario "clerk creates a two-line import and sees it on show" do
    visit "/companies/#{company.id}/stock_imports/new"
    expect(page).to have_select("stock_import[warehouse_id]", wait: 10)
    select warehouse.name, from: "stock_import[warehouse_id]"
    click_button "Add line"
    all("select.stock-line-select")[0].find("option", text: product_a.name).select_option
    all("input.stock-line-qty")[0].set("3")
    click_button "Add line"
    all("select.stock-line-select")[1].find("option", text: product_b.name).select_option
    all("input.stock-line-qty")[1].set("4")
    click_button "Save Import"
    expect(page).to have_current_path(%r{/stock_imports/(?!new)[0-9a-f-]+}, wait: 10)
    expect(page).to have_content("Back to Stock Imports", wait: 10)
    expect(page).to have_content(product_a.name)
    expect(page).to have_content(product_b.name)
    expect(StockImport.where(company: company).count).to eq(1)
  end
end
