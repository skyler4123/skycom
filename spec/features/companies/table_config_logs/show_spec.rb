require "rails_helper"

RSpec.feature "Companies::TableConfigLogs Show", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "products") }

  let!(:table_config) do
    category.default_property_mapping.table_configs.destroy_all
    create(:table_config, company: company, category: category,
      property_mapping: category.default_property_mapping, name: "Cashier Grid")
  end

  let!(:log) do
    create(:table_config_log, company: company, table_config: table_config,
      category: category, action: :updated, name: "Cashier Grid (v2)",
      category_name: category.name, employee_name: "Jane Doe",
      metadata: { "columns" => [ { "key" => "name", "name" => "Name", "visible" => true } ] })
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

  scenario "displays the log snapshot with actor, action and columns" do
    visit company_table_config_log_path(company, log)

    expect(page).to have_content("Table Config Log", wait: 10)
    expect(page).to have_content("Updated")
    expect(page).to have_content("Jane Doe")
    expect(page).to have_content("Cashier Grid (v2)")
    expect(page).to have_content("Columns Snapshot")
  end

  scenario "has back link to index page" do
    visit company_table_config_log_path(company, log)

    back_link = find("a[href*='/table_config_logs']", match: :first, wait: 10)
    expect(back_link).to be_present
  end
end
