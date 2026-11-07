require "rails_helper"

RSpec.feature "Companies::TableConfigs Management", type: :feature, js: true do
  let(:branch)   { create(:branch) }
  let(:company)  { branch.company }
  let(:owner)    { company.user }
  let(:category) { create(:category, company: company, name: "Cosmetics", resource_name: "products") }
  let(:property_mapping) do
    pm = category.default_property_mapping || create(:property_mapping, company: company, category: category, name: "Cosmetics Mapping")
    pm.update!(metadata: { "properties" => [
      { "key" => "property_string_1", "type" => "string", "name" => "Skin Type" },
      { "key" => "property_integer_1", "type" => "integer", "name" => "Stock Level" }
    ] })
    pm
  end

  let!(:table_config) do
    property_mapping.table_configs.destroy_all
    create(:table_config, company: company, category: category, property_mapping: property_mapping,
      name: "Cosmetics Table",
      metadata: { "columns" => [
        { "key" => "name", "name" => "Name", "visible" => true, "search" => true },
        { "key" => "property_string_1", "name" => "Skin Type", "visible" => true, "search" => true },
        { "key" => "property_integer_1", "name" => "Stock Level", "visible" => true,
          "filter" => { "type" => "range", "active" => true, "buckets" => [ [ nil, 10 ], [ 10, nil ] ] } }
      ] })
  end

  let!(:product) do
    create(:product, company: company, category: category, name: "Test Face Cream")
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

  scenario "index page loads and displays table" do
    visit company_table_configs_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('th', text: 'Name')
    expect(page).to have_selector('th', text: 'Category')
    expect(page).to have_selector('th', text: 'Property Mapping')
    expect(page).to have_selector('th', text: 'Actions')

    expect(page).to have_selector('tbody tr', wait: 10)
    expect(page).to have_content(table_config.name)
  end

  scenario "edit button links to edit page" do
    visit company_table_configs_path(company)
    expect(page).to have_selector('table', wait: 10)

    edit_link = find("a[href*='/edit']", match: :first)
    expect(edit_link).to be_present
  end

  scenario "name link goes to show page" do
    visit company_table_configs_path(company)
    expect(page).to have_selector('table', wait: 10)

    click_link table_config.name, match: :first
    expect(page).to have_current_path(/table_configs\/#{table_config.id}$/, wait: 10)
    expect(page).to have_content(table_config.name)
  end

  scenario "show page displays friendly column config details without raw keys" do
    visit company_table_config_path(company, table_config)
    expect(page).to have_content(table_config.name, wait: 10)

    expect(page).to have_content(/Column Config/i)
    expect(page).to have_selector("th", text: "Type")
    expect(page).to have_selector("th", text: "Search")
    expect(page).to have_selector("th", text: "Filter")
    expect(page).to have_content("Skin Type")
    expect(page).to have_content("Stock Level")
    expect(page).to have_content("Range · 2 buckets · Active")
    expect(page).to have_no_content("property_string_1")
    expect(page).to have_no_content("property_integer_1")
  end

  scenario "new page creates a table config" do
    visit new_company_table_config_path(company)
    expect(page).to have_selector('form', wait: 10)

    fill_in 'table_config[name]', with: 'New Test Table Config'
    select category.name, from: 'table_config[category_id]'
    click_button 'Save Table Config'

    expect(page).to have_content('New Test Table Config', wait: 10)
    expect(company.table_configs.find_by(name: 'New Test Table Config')).to be_present
  end

  scenario "edit page renders with the friendly column editor" do
    visit edit_company_table_config_path(company, table_config)
    expect(page).to have_selector('form', wait: 10)

    expect(page).to have_content("Edit Table Config")
    expect(page).to have_selector("th", text: "Display Name")
    expect(page).to have_selector("th", text: "Type")
    expect(page).to have_selector("th", text: "Visible")
    expect(page).to have_selector("th", text: "Search")
    expect(page).to have_selector("th", text: "Filter")
    expect(page).to have_selector("th", text: "Actions")
    expect(page).to have_no_selector("th", text: "Key")
  end

  scenario "hiding a column updates the live Products table" do
    visit edit_company_table_config_path(company, table_config)
    expect(page).to have_selector('[data-column-row="property_string_1"]', wait: 10)

    within('[data-column-row="property_string_1"]') do
      uncheck "col-visible-property_string_1"
    end

    click_button 'Save Changes'
    expect(page).to have_current_path(/table_configs\/#{table_config.id}$/, wait: 10)

    company.table_configs.reset
    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
      "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
      "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
      "branches" => [],
      "departments" => [],
      "roles" => []
    )

    page.execute_script("localStorage.clear()")
    payload = {
      user: JSON.parse(owner.to_json),
      companies: [ company_data ],
      enums: {},
      employees: []
    }
    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")

    visit company_products_path(company, category_id: category.id)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('th', text: 'Name')
    expect(page).to have_no_selector('th', text: 'Skin Type')
  end

  scenario "show page has clickable property mapping link" do
    visit company_table_config_path(company, table_config)
    expect(page).to have_content(table_config.name, wait: 10)

    pm_link = find("a[href*='/property_mappings/#{property_mapping.id}']", match: :first)
    expect(pm_link).to be_present
    expect(pm_link).to have_text(property_mapping.name)
  end

  scenario "edit page has property mapping edit link" do
    visit edit_company_table_config_path(company, table_config)
    expect(page).to have_selector('form', wait: 10)

    pm_link = find("a[href*='/property_mappings/#{property_mapping.id}/edit']", match: :first)
    expect(pm_link).to be_present
  end
end
