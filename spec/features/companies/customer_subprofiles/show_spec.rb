require "rails_helper"

RSpec.feature "Companies::CustomerSubprofiles Show", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:customer) { create(:customer, company: company) }
  let(:profile_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "customer_profiles") }
  let(:profile) { Seed::CustomerProfileService.create(company: company, customer: customer, category: profile_category, name: "Profile 1") }
  let!(:sub) { Seed::CustomerSubprofileService.create(company: company, customer: customer, customer_profile: profile, name: "Subprofile 11", description: "First sub") }

  before do
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

  scenario "displays subprofile" do
    visit company_customer_subprofile_path(company, sub)
    expect(page).to have_content("Subprofile 11", wait: 10)
    expect(page).to have_content("First sub", wait: 10)
  end
end
