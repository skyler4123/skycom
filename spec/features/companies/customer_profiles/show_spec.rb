require "rails_helper"

RSpec.feature "Companies::CustomerProfiles Show", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:customer) { create(:customer, company: company) }
  let!(:profile) { Seed::CustomerProfileService.create(company: company, customer: customer, name: "Profile 1", description: "First profile") }

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

  scenario "displays profile name and description" do
    visit company_customer_profile_path(company, profile)
    expect(page).to have_content("Profile 1", wait: 10)
    expect(page).to have_content("First profile", wait: 10)
  end

  scenario "has edit button linking to edit page" do
    visit company_customer_profile_path(company, profile)
    edit_link = find("a[href*='/customer_profiles/#{profile.id}/edit']", match: :first)
    expect(edit_link).to be_present
  end

  scenario "has back link to index" do
    visit company_customer_profile_path(company, profile)
    back_link = find("a[href*='/companies/#{company.id}/customer_profiles']", match: :first)
    expect(back_link).to be_present
  end
end
