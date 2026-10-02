# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::StockPendings edit", type: :feature, js: true do
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
  let!(:pending) do
    StockPendings::HoldService.call(
      company: company, warehouse: warehouse, stock: stock,
      quantity: 4, business_type: :manual, name: "Morning Count Hold"
    )[:stock_pending]
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

  scenario "clerk renames the hold and lands on the show page" do
    visit "/companies/#{company.id}/stock_pendings/#{pending.id}/edit"

    expect(page).to have_field("stock_pending[name]", wait: 10)
    fill_in "stock_pending[name]", with: "Renamed Hold"
    fill_in "stock_pending[reason]", with: "Recounted"
    click_button "Save Changes"

    expect(page).to have_current_path("/companies/#{company.id}/stock_pendings/#{pending.id}", wait: 10)
    expect(page).to have_content("Renamed Hold", wait: 10)
    expect(pending.reload.quantity).to eq(4)
  end
end
