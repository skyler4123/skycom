require "rails_helper"

RSpec.feature "Companies::TaxConfigs Management", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

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

  scenario "tax config page loads" do
    visit company_tax_config_path(company)

    expect(page).to have_content("Tax Config", wait: 10)
    expect(page).to have_content("Save Config", wait: 10)
  end

  scenario "saves the POS tax rate and label" do
    visit company_tax_config_path(company)

    find('input[name="pos_tax_rate_percent"]', wait: 10).set("8")
    find('input[name="pos_tax_name"]').set("Sales tax")
    click_button "Save Config"

    expect(page).to have_field("pos_tax_rate_percent", with: "8", wait: 10)

    config = TaxConfig.for_company!(company).reload
    expect(config.pos_tax_rate_bp).to eq(800)
    expect(config.pos_tax_name).to eq("Sales tax")
  end
end
