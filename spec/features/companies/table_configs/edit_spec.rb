# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::TableConfigs edit search/filter", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "products") }
  let(:property_mapping) do
    pm = category.default_property_mapping
    pm.update!(metadata: {
      "properties" => [
        { "key" => "property_string_1", "name" => "Color", "type" => "string" },
        { "key" => "property_integer_1", "name" => "Qty", "type" => "integer" },
        { "key" => "property_integer_2", "name" => "Tier", "type" => "integer",
          "input_type" => "select",
          "options" => [ { "value" => 1, "label" => "Gold" }, { "value" => 2, "label" => "Silver" } ] },
        { "key" => "property_boolean_1", "name" => "Active", "type" => "boolean" },
        { "key" => "property_datetime_1", "name" => "Released", "type" => "datetime" }
      ],
      "extra_columns" => [
        { "key" => "extra_1", "name" => "Extra Demo 1", "type" => "string" }
      ]
    })
    pm
  end
  let!(:config) do
    property_mapping.table_configs.destroy_all
    TableConfig.create!(company: company, category: category, property_mapping: property_mapping,
      resource_name: "products", name: "Products Grid",
      metadata: { "columns" => [
        { "key" => "name", "name" => "Name", "visible" => true },
        { "key" => "property_string_1", "name" => "Color", "visible" => true, "search" => true },
        { "key" => "property_integer_1", "name" => "Qty", "visible" => true },
        { "key" => "property_integer_2", "name" => "Tier", "visible" => true },
        { "key" => "property_boolean_1", "name" => "Active", "visible" => true },
        { "key" => "property_datetime_1", "name" => "Released", "visible" => true }
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

  scenario "edit page hides raw keys and shows friendly type badges" do
    visit edit_company_table_config_path(company, config)
    expect(page).to have_selector("th", text: "Display Name", wait: 10)
    expect(page).to have_selector("th", text: "Type")
    expect(page).to have_selector("th", text: "Visible")
    expect(page).to have_selector("th", text: "Search")
    expect(page).to have_selector("th", text: "Filter")
    expect(page).to have_selector("th", text: "Actions")
    expect(page).to have_no_selector("th", text: "Key")

    within('[data-column-row="property_string_1"]') do
      expect(page).to have_content("Color")
      expect(page).to have_content("Text")
      expect(page).to have_content(/property mapping/i)
    end

    within('[data-column-row="property_integer_2"]') do
      expect(page).to have_content("Tier")
      expect(page).to have_content("Choice list")
    end

    expect(page).to have_no_content("property_string_1")
    expect(page).to have_no_content("property_integer_2")
  end

  scenario "all column display names are read-only" do
    visit edit_company_table_config_path(company, config)
    expect(page).to have_selector('[data-column-row="name"]', wait: 10)

    expect(page).to have_no_selector('input[type="text"][name*="[columns]"][name*="[name]"]')
    expect(page).to have_selector('input[type="hidden"][name*="[columns]"][name*="[name]"]', visible: :all)
  end

  scenario "Add Column does not add on select change; clicking Add Column adds it" do
    visit edit_company_table_config_path(company, config)
    expect(page).to have_selector("#new-column-slot", wait: 10)
    expect(page).to have_no_selector('[data-column-row="description"]')

    select "Description — Text", from: "new-column-slot"
    expect(page).to have_no_selector('[data-column-row="description"]')

    click_button "Add Column"
    within('[data-column-row="description"]') do
      expect(page).to have_content("Description")
      expect(page).to have_content("Text")
    end
  end

  scenario "reorders columns up and down and persists the order" do
    visit edit_company_table_config_path(company, config)
    expect(page).to have_selector('[data-column-row="name"]', wait: 10)

    find('[data-action*="moveColumn"][data-key="name"][data-direction="down"]').click
    click_button "Save Changes"

    expect(page).to have_current_path(company_table_config_path(company, config), wait: 10)
    expect(config.reload.columns.map { |column| column["key"] }.first(3)).to eq(
      [ "property_string_1", "name", "property_integer_1" ]
    )

    visit edit_company_table_config_path(company, config)
    expect(page).to have_selector('[data-column-row="property_string_1"]', wait: 10)
  end

  scenario "visible and search toggles persist through save" do
    visit edit_company_table_config_path(company, config)
    expect(page).to have_selector('[data-column-row="property_string_1"]', wait: 10)

    within('[data-column-row="property_string_1"]') do
      uncheck "col-visible-property_string_1"
      uncheck "col-search-property_string_1"
    end
    within('[data-column-row="name"]') do
      check "col-search-name"
    end

    click_button "Save Changes"
    expect(page).to have_current_path(company_table_config_path(company, config), wait: 10)

    color = config.reload.columns.find { |column| column["key"] == "property_string_1" }
    name = config.reload.columns.find { |column| column["key"] == "name" }
    expect(color).to include("visible" => false, "search" => false)
    expect(name).to include("search" => true)
  end

  scenario "range filter panel saves buckets and active state" do
    visit edit_company_table_config_path(company, config)
    expect(page).to have_selector('[data-column-row="property_integer_1"]', wait: 10)

    find('[data-action*="toggleFilterPanel"][data-key="property_integer_1"]').click
    within('[data-filter-panel="property_integer_1"]') do
      select "Range", from: "col-filter-type-property_integer_1"
      find('[data-action*="removeFilterBucket"][data-bucket-index="1"]').click
      fill_in "col-filter-bucket-property_integer_1-0-from", with: "10"
      fill_in "col-filter-bucket-property_integer_1-0-to", with: "20"
    end

    click_button "Save Changes"
    expect(page).to have_current_path(company_table_config_path(company, config), wait: 10)
    expect(config.reload.columns.find { |column| column["key"] == "property_integer_1" }["filter"]).to eq(
      "type" => "range", "active" => true, "buckets" => [ [ 10, 20 ] ]
    )
  end

  scenario "only one filter panel is open at a time" do
    visit edit_company_table_config_path(company, config)
    expect(page).to have_selector('[data-column-row="property_integer_1"]', wait: 10)

    find('[data-action*="toggleFilterPanel"][data-key="property_integer_1"]').click
    expect(page).to have_selector('[data-filter-panel="property_integer_1"]:not(.hidden)')

    find('[data-action*="toggleFilterPanel"][data-key="property_integer_2"]').click
    expect(page).to have_selector('[data-filter-panel="property_integer_2"]:not(.hidden)')
    expect(page).to have_selector('[data-filter-panel="property_integer_1"].hidden', visible: :all)
  end

  scenario "adds and removes filter buckets inside the panel" do
    visit edit_company_table_config_path(company, config)
    expect(page).to have_selector('[data-column-row="property_integer_1"]', wait: 10)

    find('[data-action*="toggleFilterPanel"][data-key="property_integer_1"]').click
    within('[data-filter-panel="property_integer_1"]') do
      select "Range", from: "col-filter-type-property_integer_1"
      expect(page).to have_selector("[data-filter-bucket]", count: 2)

      click_button "Add Bucket"
      expect(page).to have_selector("[data-filter-bucket]", count: 3)

      all('[data-action*="removeFilterBucket"]').last.click
      expect(page).to have_selector("[data-filter-bucket]", count: 2)
    end

    click_button "Save Changes"
    expect(page).to have_current_path(company_table_config_path(company, config), wait: 10)
    expect(config.reload.columns.find { |column| column["key"] == "property_integer_1" }["filter"]["buckets"]).to eq(
      [ [ nil, 100 ], [ 100, nil ] ]
    )
  end

  scenario "enum filter shows Property Mapping choices and saves" do
    visit edit_company_table_config_path(company, config)
    expect(page).to have_selector('[data-column-row="property_integer_2"]', wait: 10)

    find('[data-action*="toggleFilterPanel"][data-key="property_integer_2"]').click
    within('[data-filter-panel="property_integer_2"]') do
      select "Choice list", from: "col-filter-type-property_integer_2"
      expect(page).to have_content("1 = Gold")
      expect(page).to have_content("2 = Silver")
    end

    click_button "Save Changes"
    expect(page).to have_current_path(company_table_config_path(company, config), wait: 10)
    expect(config.reload.columns.find { |column| column["key"] == "property_integer_2" }["filter"]).to eq(
      "type" => "enum", "active" => true
    )
  end

  scenario "an invalid bucket blocks the save client-side with a toast and no DB change" do
    visit edit_company_table_config_path(company, config)
    expect(page).to have_selector('[data-column-row="property_integer_1"]', wait: 10)

    find('[data-action*="toggleFilterPanel"][data-key="property_integer_1"]').click
    within('[data-filter-panel="property_integer_1"]') do
      select "Range", from: "col-filter-type-property_integer_1"
      find('[data-action*="removeFilterBucket"][data-bucket-index="1"]').click
      fill_in "col-filter-bucket-property_integer_1-0-from", with: "500"
      fill_in "col-filter-bucket-property_integer_1-0-to", with: "100"
    end

    click_button "Save Changes"

    expect(page).to have_current_path(edit_company_table_config_path(company, config), wait: 10)
    expect(page).to have_content("From must be less than To", wait: 10)
    expect(config.reload.columns.find { |column| column["key"] == "property_integer_1" }).not_to have_key("filter")
  end

  scenario "removing a column persists and updates the config" do
    visit edit_company_table_config_path(company, config)
    expect(page).to have_selector('[data-column-row="property_integer_1"]', wait: 10)

    find('[data-action*="removeColumn"][data-key="property_integer_1"]').click
    click_button "Save Changes"

    expect(page).to have_current_path(company_table_config_path(company, config), wait: 10)
    expect(config.reload.columns.map { |column| column["key"] }).not_to include("property_integer_1")
  end

  scenario "name column cannot be removed" do
    visit edit_company_table_config_path(company, config)
    expect(page).to have_selector('[data-column-row="name"]', wait: 10)

    remove_button = find('[data-action*="removeColumn"][data-key="name"]', visible: :all)
    expect(remove_button).to be_disabled
  end
end
