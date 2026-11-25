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
    expect(page).to have_content("Default tax code", wait: 10)
    expect(page).to have_button("Save Config", wait: 10)
  end

  scenario "shows the first-step empty state when there are no tax codes" do
    visit company_tax_config_path(company)

    expect(page).to have_content("No tax codes yet", wait: 10)
    expect(page).to have_link("Add tax code", wait: 10)
  end

  scenario "saves the default tax code" do
    code = create(:tax_code, company: company, name: "VAT 10%", rate_bp: 1_000)

    visit company_tax_config_path(company)
    select "VAT 10% (10%)", from: "default_tax_code_id"
    click_button "Save Config"

    expect(page).to have_select("default_tax_code_id", selected: "VAT 10% (10%)", wait: 10)
    expect(TaxConfig.for_company!(company).reload.default_tax_code_id).to eq(code.id)
  end

  scenario "warns when codes exist but no default is set" do
    create(:tax_code, company: company, name: "VAT 10%")

    visit company_tax_config_path(company)

    expect(page).to have_content("No default is set", wait: 10)
  end
end
