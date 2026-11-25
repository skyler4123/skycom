# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::Services Edit", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:owner) { company.user }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "services") }
  let!(:service) do
    Service.create!(
      company: company,
      branch: branch,
      category: category,
      property_mapping: category.default_property_mapping,
      name: "Consultation",
      business_type: :b2c
    )
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
      enums: {
        service: {
          business_types: [
            { name: "B2B", value: "b2b" },
            { name: "B2C", value: "b2c" }
          ],
          lifecycle_statuses: [],
          workflow_statuses: [
            { name: "Active", value: "active" },
            { name: "Inactive", value: "inactive" }
          ]
        }
      },
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "assigns a tax code and shows it on the service page" do
    code = create(:tax_code, company: company, name: "VAT 5%", rate_bp: 500)

    visit edit_company_service_path(company, service)

    expect(page).to have_selector('select[name="service[tax_code_id]"]', wait: 10)
    select "VAT 5% (5%)", from: "service[tax_code_id]"
    click_button "Save Changes"

    expect(page).to have_content("VAT 5%", wait: 10)
    expect(service.reload.tax_code).to eq(code)
  end
end
