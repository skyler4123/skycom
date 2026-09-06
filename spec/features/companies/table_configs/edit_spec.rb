# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::TableConfigs edit search/filter", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "products") }
  let(:property_mapping) do
    pm = category.default_property_mapping
    pm.update!(metadata: { "properties" => [
      { "key" => "property_string_1", "name" => "Color", "type" => "string", "validates" => {} },
      { "key" => "property_integer_1", "name" => "Qty", "type" => "integer", "validates" => {} }
    ] })
    pm
  end
  let!(:config) do
    property_mapping.table_configs.destroy_all
    TableConfig.create!(company: company, category: category, property_mapping: property_mapping,
      resource_name: "products", name: "Products Grid",
      metadata: { "columns" => [
        { "key" => "property_string_1", "name" => "Color", "visible" => true, "search" => false },
        { "key" => "property_integer_1", "name" => "Qty", "visible" => true }
      ] })
  end

  before do
    property_mapping
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

  scenario "enabling search and a range filter persists through the form" do
    visit edit_company_table_config_path(company, config)
    expect(page).to have_selector("th", text: "Search", wait: 10)
    expect(page).to have_selector("th", text: "Filter")

    check "col-search-0"
    fill_in "col-filter-1", with: '{"type":"range","buckets":[[null,100],[100,null]]}'
    click_button "Save Changes"

    expect(page).to have_current_path(company_table_config_path(company, config), wait: 10)
    expect(config.reload.columns[0]).to include("search" => true)
    expect(config.columns[1]["filter"]).to eq("type" => "range", "buckets" => [ [ nil, 100 ], [ 100, nil ] ])

    visit edit_company_table_config_path(company, config)
    expect(page).to have_checked_field("col-search-0", wait: 10)
    expect(page).to have_field("col-filter-1", with: /"type":"range"/)
  end

  scenario "string column has no filter editor; integer column offers a range skeleton placeholder" do
    visit edit_company_table_config_path(company, config)
    expect(page).to have_selector("th", text: "Search", wait: 10)
    expect(page).to have_no_field("col-filter-0")
    expect(page).to have_field("col-filter-1", placeholder: /"type":"range"/)
  end

  scenario "invalid filter JSON blocks the save with an alert" do
    visit edit_company_table_config_path(company, config)
    expect(page).to have_field("col-filter-1", wait: 10)
    fill_in "col-filter-1", with: "{not json"
    click_button "Save Changes"

    expect(page).to have_current_path(edit_company_table_config_path(company, config), wait: 10)
    expect(config.reload.columns[1]).not_to have_key("filter")
  end
end
