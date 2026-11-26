# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::Products computed columns", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "products") }

  let!(:table_config) do
    category.default_property_mapping.table_configs.destroy_all
    TableConfig.create!(
      company: company,
      category: category,
      property_mapping: category.default_property_mapping,
      resource_name: "products",
      name: "Products Grid",
      metadata: { "columns" => [
        { "key" => "name", "name" => "Name", "visible" => true },
        { "key" => "quantity", "name" => "Quantity", "visible" => true }
      ] }
    )
  end

  let!(:product) { create(:product, company: company, category: category, name: "Computed Product") }
  let!(:empty_product) { create(:product, company: company, category: category, name: "No Stock Product") }
  let!(:warehouse_a) { create(:warehouse, company: company) }
  let!(:warehouse_b) { create(:warehouse, company: company) }

  before do
    Stock.create!(company: company, warehouse: warehouse_a, product: product, quantity: 5, pending: 0)
    Stock.create!(company: company, warehouse: warehouse_b, product: product, quantity: 3, pending: 0)

    sign_in(owner)
    seed_client_cache
  end

  def seed_client_cache
    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
      "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
      "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
      "branches" => [],
      "departments" => [],
      "roles" => []
    )

    payload = {
      user: JSON.parse(owner.to_json),
      companies: [ company_data ],
      enums: {},
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "shows the computed quantity summed across warehouses without a filter control" do
    visit company_products_path(company, category_id: category.id)

    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_selector("th", text: "Quantity")

    within("tbody tr", text: product.name) do
      expect(page).to have_content("8")
    end

    within("tbody tr", text: empty_product.name) do
      expect(page).to have_content("0")
    end

    expect(page).to have_no_selector('select[name="filters[quantity]"]')
  end

  scenario "hiding the computed column persists" do
    visit edit_company_table_config_path(company, table_config)
    expect(page).to have_selector('[data-column-row="quantity"]', wait: 10)

    within('[data-column-row="quantity"]') do
      expect(page).to have_content(/computed/i)
      uncheck "col-visible-quantity"
    end

    click_button "Save Changes"
    expect(page).to have_current_path(company_table_config_path(company, table_config), wait: 10)

    expect(table_config.reload.columns.find { |column| column["key"] == "quantity" }["visible"]).to be(false)

    seed_client_cache
    visit company_products_path(company, category_id: category.id)
    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_no_selector("th", text: "Quantity")
  end
end
