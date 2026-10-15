require "rails_helper"

RSpec.feature "Companies::CustomerSubprofiles New", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:customer) { create(:customer, company: company) }
  let(:profile_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "customer_profiles") }
  let(:profile) { Seed::CustomerProfileService.create(company: company, customer: customer, category: profile_category, name: "Profile 1") }

  before do
    sign_in(owner)
    page.execute_script("localStorage.clear()")
    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
      "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
      "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
      "branches" => [], "departments" => [], "roles" => []
    )
    payload = {
      user: JSON.parse(owner.to_json), companies: [ company_data ],
      enums: { customer_subprofile: { business_types: [ { name: "General", value: "general" }, { name: "Special", value: "special" } ], lifecycle_statuses: [], workflow_statuses: [] } },
      employees: []
    }
    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "creates subprofile and redirects to show" do
    visit new_company_customer_subprofile_path(company)
    fill_in "customer_subprofile[name]", with: "Subprofile 11"
    fill_in "customer_subprofile[customer_id]", with: customer.id
    fill_in "customer_subprofile[customer_profile_id]", with: profile.id
    page.execute_script("document.querySelector('select[name=\"customer_subprofile[business_type]\"]').value = 'general'")
    click_button "Save Customer Subprofile"
    expect(page).to have_current_path(/\/customer_subprofiles\//, wait: 10)
    expect(page).to have_content("Subprofile 11", wait: 10)
    expect(CustomerSubprofile.find_by(name: "Subprofile 11")).to be_present
  end
end
