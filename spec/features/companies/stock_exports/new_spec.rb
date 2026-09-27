# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::StockExports New", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let!(:warehouse) { create(:warehouse, company: company, name: "Main") }
  let!(:product_a) { create(:product, company: company, name: "Gadget #{SecureRandom.hex(4)}") }
  let!(:stock_a) do
    Stock.create!(company: company, warehouse: warehouse, product: product_a,
      quantity: 10, name: "Exp-A", code: "STK-EXPA-#{SecureRandom.hex(3).upcase}")
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

  scenario "creates a one-line export and lands on show" do
    visit "/companies/#{company.id}/stock_exports/new"
    expect(page).to have_select("stock_export[warehouse_id]", wait: 10)
    select warehouse.name, from: "stock_export[warehouse_id]"
    click_button "Add line"
    all("select.stock-line-select")[0].find("option", text: product_a.name).select_option
    all("input.stock-line-qty")[0].set("2")
    click_button "Save Export"
    expect(page).to have_current_path(%r{/stock_exports/(?!new)[0-9a-f-]+}, wait: 10)
    expect(page).to have_content("Back to Stock Exports", wait: 10)
    expect(page).to have_content(product_a.name)
    expect(StockExport.where(company: company).count).to eq(1)
  end

  scenario "export beyond availability 422s and persists nothing" do
    visit "/companies/#{company.id}/stock_exports/new"
    expect(page).to have_select("stock_export[warehouse_id]", wait: 10)
    select warehouse.name, from: "stock_export[warehouse_id]"
    click_button "Add line"
    all("select.stock-line-select")[0].find("option", text: product_a.name).select_option
    all("input.stock-line-qty")[0].set("99999")
    click_button "Save Export"
    expect(page).to have_content(/insufficient|availability/i, wait: 10)
    expect(StockExport.where(company: company).count).to eq(0)
  end
end
