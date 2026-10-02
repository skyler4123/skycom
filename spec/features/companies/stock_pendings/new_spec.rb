# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::StockPendings creation", type: :feature, js: true do
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
  end

  scenario "clerk holds stock and availability drops" do
    visit "/companies/#{company.id}/stock_pendings/new"

    expect(page).to have_select("warehouse_id", wait: 10)
    select warehouse.name, from: "warehouse_id"
    select "#{product.name} (Available: 20)", from: "stock_pending[stock_id]"
    fill_in "stock_pending[quantity]", with: "4"
    fill_in "stock_pending[name]", with: "Morning Count Hold"
    click_button "Create"

    expect(page).to have_current_path(%r{/stock_pendings/(?!new)[0-9a-f-]+}, wait: 10)
    expect(page).to have_content("Morning Count Hold", wait: 10)
    expect(stock.reload.pending).to eq(4)
  end

  scenario "over-hold keeps the page and changes nothing" do
    visit "/companies/#{company.id}/stock_pendings/new"

    expect(page).to have_select("warehouse_id", wait: 10)
    select warehouse.name, from: "warehouse_id"
    select "#{product.name} (Available: 20)", from: "stock_pending[stock_id]"
    fill_in "stock_pending[quantity]", with: "99"
    click_button "Create"

    expect(page).to have_content("Insufficient stock", wait: 10)
    expect(page).to have_current_path(%r{/stock_pendings/new}, wait: 10)
    expect(stock.reload.pending).to eq(0)
    expect(StockPending.count).to eq(0)
  end
end
