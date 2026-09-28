# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::StockTransfers Flow", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let!(:warehouse_a) { create(:warehouse, company: company, name: "WH-A") }
  let!(:warehouse_b) { create(:warehouse, company: company, name: "WH-B") }
  let!(:product_a) { create(:product, company: company, name: "Gadget #{SecureRandom.hex(4)}") }
  let!(:stock_a) do
    Stock.create!(company: company, warehouse: warehouse_a, product: product_a,
      quantity: 20, name: "Trf-A", code: "STK-TRFA-#{SecureRandom.hex(3).upcase}")
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

  scenario "clerk creates, initiates, and receives a transfer" do
    visit "/companies/#{company.id}/stock_transfers/new"
    expect(page).to have_select("stock_transfer[warehouse_id]", wait: 10)
    select warehouse_a.name, from: "stock_transfer[warehouse_id]"
    select warehouse_b.name, from: "stock_transfer[destination_warehouse_id]"
    click_button "Add line"
    all("select.stock-line-select")[0].find("option", text: product_a.name).select_option
    all("input.stock-line-qty")[0].set("5")
    click_button "Save Transfer"
    expect(page).to have_current_path(%r{/stock_transfers/(?!new)[0-9a-f-]+}, wait: 10)
    expect(page).to have_content("Back to Stock Transfers", wait: 10)
    click_button "Initiate"
    expect(page).to have_content("Initiated", wait: 10)
    click_button "Receive"
    expect(page).to have_content("Received", wait: 10)
    expect(Stock.find_by(warehouse: warehouse_a, product: product_a).quantity).to eq(15)
    expect(Stock.find_by(warehouse: warehouse_b, product: product_a).quantity).to eq(5)
  end

  scenario "received transfer show page has no phase buttons" do
    transfer = create(:stock_transfer, company: company, warehouse: warehouse_a,
      destination_warehouse: warehouse_b)
    transfer.update!(workflow_status: :received)
    visit "/companies/#{company.id}/stock_transfers/#{transfer.id}"
    expect(page).to have_content("Back to Stock Transfers", wait: 10)
    expect(page).to have_no_button("Receive")
    expect(page).to have_no_button("Initiate")
  end
end
