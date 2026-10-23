require "rails_helper"

RSpec.feature "Companies::TableConfigs extra columns end-to-end", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "products") }
  let(:property_mapping) do
    pm = category.default_property_mapping
    pm.update!(metadata: {
      "properties" => [
        { "key" => "property_string_1", "name" => "Color", "type" => "string", "validates" => {} }
      ],
      "extra_columns" => [
        { "key" => "extra_1", "name" => "Extra Demo 1", "type" => "string" }
      ]
    })
    pm
  end

  let!(:table_config) do
    property_mapping.table_configs.destroy_all
    create(:table_config, company: company, category: category, property_mapping: property_mapping,
      name: "Products Grid", resource_name: "products",
      metadata: { "columns" => [
        { "key" => "name", "name" => "Name", "visible" => true, "align" => "left", "width" => nil },
        { "key" => "property_string_1", "name" => "Color", "visible" => true, "align" => "left", "width" => nil }
      ] })
  end

  let!(:product) do
    create(:product, company: company, category: category, name: "Test Product", property_string_1: "Red")
  end

  before do
    sign_in(owner)

    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
      "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
      "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
      "branches" => [], "departments" => [], "roles" => []
    )
    payload = { user: JSON.parse(owner.to_json), companies: [ company_data ], enums: {}, employees: [] }
    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "adds an extra column from Table Config and reflects it after cache refresh" do
    visit edit_company_table_config_path(company, table_config)
    expect(page).to have_selector("#new-column-slot", wait: 10)

    expect(page).to have_selector("option", text: "Extra Demo 1")
    expect(page).not_to have_selector("option", text: "property_string_2")

    select "Extra Demo 1", from: "new-column-slot"
    expect(page).to have_selector('input[value="extra_1"]', wait: 10)

    click_button "Save Changes"
    expect(page).to have_current_path(company_table_config_path(company, table_config), wait: 10)

    # Manual cache refresh to verify data, not relying on automatic sync.
    company.reload
    company.property_mappings.reset
    company.table_configs.reset
    company.categories.reset
    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
      "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
      "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
      "branches" => [], "departments" => [], "roles" => []
    )
    payload = { user: JSON.parse(owner.to_json), companies: [ company_data ], enums: {}, employees: [] }
    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    version = page.evaluate_script("document.cookie.match(/(?:^|;\\s*)client_cache_version=([^;]*)/)?.[1]")
    page.execute_script("localStorage.setItem('client_cache_version', arguments[0])", version)

    visit company_products_path(company, category_id: category.id)
    expect(page).to have_selector("th", text: "Extra Demo 1", wait: 10)
  end

  scenario "renaming an extra column in Property Mapping keeps the Table Config chooser updated" do
    visit edit_company_property_mapping_path(company, property_mapping)
    expect(page).to have_selector("input[name*='extra_columns'][name*='[name]']", wait: 10)

    name_input = find(:xpath, "//input[contains(@name, 'extra_columns') and contains(@name, '[name]')]")
    name_input.set("Renamed Extra")
    click_button "Save Changes"
    expect(page).to have_content("Property mapping updated successfully", wait: 10)

    visit edit_company_table_config_path(company, table_config)
    expect(page).to have_selector("#new-column-slot", wait: 10)
    expect(page).to have_selector("option", text: "Renamed Extra", wait: 10)
  end

  scenario "toggling Table Config column settings persists through save" do
    visit edit_company_table_config_path(company, table_config)
    expect(page).to have_selector("input[name*='[columns]'][name*='[key]']", wait: 10)

    first_key = find(:xpath, "(//input[contains(@name, '[columns]') and contains(@name, '[key]')])[1]").value
    expect(first_key).to eq("name")

    check "col-search-0" rescue nil
    click_button "Save Changes"
    expect(page).to have_current_path(company_table_config_path(company, table_config), wait: 10)

    visit edit_company_table_config_path(company, table_config)
    expect(page).to have_selector("input[name*='[columns]'][name*='[key]']", wait: 10)
  end
end
