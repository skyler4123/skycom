# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::TableConfigs edit search/filter", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "products") }
  let(:property_mapping) do
    pm = category.default_property_mapping
    pm.update!(metadata: { "properties" => [
      { "key" => "property_string_1", "name" => "Color", "type" => "string" },
      { "key" => "property_integer_1", "name" => "Qty", "type" => "integer" }
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
    expect(page).to have_no_selector("th", text: "Align")
    expect(page).to have_no_selector("th", text: "Width")
    expect(page).to have_no_selector('textarea[name*="[filter]"]')

    check "col-search-0"
    select "Range", from: "col-filter-type-1"
    expect(page).to have_field("col-filter-active-1", checked: true)

    find('[data-action*="removeFilterBucket"][data-bucket-index="1"]').click
    fill_in "col-filter-bucket-1-0-from", with: "10"
    fill_in "col-filter-bucket-1-0-to", with: "20"

    click_button "Save Changes"

    expect(page).to have_current_path(company_table_config_path(company, config), wait: 10)
    expect(config.reload.columns[0]).to include("search" => true)
    expect(config.columns[1]["filter"]).to eq(
      "type" => "range", "active" => true, "buckets" => [ [ 10, 20 ] ]
    )

    visit edit_company_table_config_path(company, config)
    expect(page).to have_checked_field("col-search-0", wait: 10)
    expect(page).to have_checked_field("col-filter-active-1")
    expect(page).to have_select("col-filter-type-1", selected: "Range")
    expect(page).to have_field("col-filter-bucket-1-0-from", with: "10")
    expect(page).to have_field("col-filter-bucket-1-0-to", with: "20")
  end

  scenario "unchecking the Filter active box stores the config disabled" do
    visit edit_company_table_config_path(company, config)
    expect(page).to have_field("col-filter-type-1", wait: 10)

    select "Range", from: "col-filter-type-1"
    uncheck "col-filter-active-1"
    click_button "Save Changes"

    expect(page).to have_current_path(company_table_config_path(company, config), wait: 10)
    expect(config.reload.columns[1]["filter"]).to include("type" => "range", "active" => false)

    visit edit_company_table_config_path(company, config)
    expect(page).to have_unchecked_field("col-filter-active-1", wait: 10)
  end

  scenario "string column has no filter editor; integer column offers typed range controls" do
    visit edit_company_table_config_path(company, config)
    expect(page).to have_selector("th", text: "Search", wait: 10)

    expect(page).to have_no_selector("#col-filter-type-0")
    expect(page).to have_selector("#col-filter-type-1")
    expect(page).to have_no_selector('textarea[name*="[filter]"]')
  end

  scenario "adds and removes filter buckets" do
    visit edit_company_table_config_path(company, config)
    select "Range", from: "col-filter-type-1", wait: 10

    expect(page).to have_selector('[data-action*="removeFilterBucket"]', count: 2)
    click_button "Add Bucket"
    expect(page).to have_selector('[data-action*="removeFilterBucket"]', count: 3)

    all('[data-action*="removeFilterBucket"]').last.click
    expect(page).to have_selector('[data-action*="removeFilterBucket"]', count: 2)
  end

  scenario "an invalid bucket blocks the save with an alert" do
    visit edit_company_table_config_path(company, config)
    select "Range", from: "col-filter-type-1", wait: 10

    find('[data-action*="removeFilterBucket"][data-bucket-index="1"]').click
    fill_in "col-filter-bucket-1-0-from", with: "500"
    fill_in "col-filter-bucket-1-0-to", with: "100"

    click_button "Save Changes"

    expect(page).to have_current_path(edit_company_table_config_path(company, config), wait: 10)
    expect(config.reload.columns[1]).not_to have_key("filter")
  end
end
