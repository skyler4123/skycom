require "rails_helper"

RSpec.feature "Companies::TableConfigLogs Management", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "products") }

  let!(:table_config) do
    category.default_property_mapping.table_configs.destroy_all
    create(:table_config, company: company, category: category,
      property_mapping: category.default_property_mapping, name: "Cashier Grid")
  end

  let!(:created_log) do
    create(:table_config_log, company: company, table_config: table_config,
      category: category, action: :created, name: "Cashier Grid",
      category_name: category.name, employee_name: "Jane Doe")
  end

  let!(:updated_log) do
    create(:table_config_log, company: company, table_config: table_config,
      category: category, action: :updated, name: "Cashier Grid (v2)",
      category_name: category.name, employee_name: "John Smith")
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

  scenario "index page loads and displays log rows with actor and action" do
    visit company_table_config_logs_path(company)

    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_content("Table Config Logs")
    expect(page).to have_selector("th", text: "Name")
    expect(page).to have_selector("th", text: "Changed By")
    expect(page).to have_content("Cashier Grid")
    expect(page).to have_content("Created")
    expect(page).to have_content("Updated")
    expect(page).to have_content("Jane Doe")
    expect(page).to have_content("John Smith")
  end

  scenario "index has filter controls for config, category, action and dates" do
    visit company_table_config_logs_path(company)

    expect(page).to have_selector("select[name='table_config_id']", wait: 10)
    expect(page).to have_selector("select[name='category_id']")
    expect(page).to have_selector("select[name='log_action']")
    expect(page).to have_selector("input[name='from']")
    expect(page).to have_selector("input[name='to']")
  end

  scenario "filtering by action narrows the rows" do
    visit company_table_config_logs_path(company)
    expect(page).to have_content("John Smith", wait: 10)

    select "Created", from: "log_action"
    click_button "Search"

    expect(page).to have_content("Jane Doe", wait: 10)
    expect(page).to have_no_content("John Smith")
  end

  scenario "eye icon links to the log show page" do
    visit company_table_config_logs_path(company)
    expect(page).to have_selector("table", wait: 10)

    eye_link = find("a[href*='/table_config_logs/#{created_log.id}']", match: :first)
    expect(eye_link).to be_present
  end
end
