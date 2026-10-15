require "rails_helper"

RSpec.feature "Companies::CustomerProfiles New", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:customer) { create(:customer, company: company) }

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
      user: JSON.parse(owner.to_json),
      companies: [ company_data ],
      enums: {
        customer_profile: {
          business_types: [
            { name: "General", value: "general" },
            { name: "Special", value: "special" }
          ],
          lifecycle_statuses: [], workflow_statuses: []
        }
      },
      employees: []
    }
    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "renders new form with name and parent fields" do
    visit new_company_customer_profile_path(company)
    expect(page).to have_selector('input[name="customer_profile[name]"]', wait: 10)
    expect(page).to have_selector('select[name="customer_profile[business_type]"]', wait: 10)
    expect(page).to have_selector('input[name="customer_profile[customer_id]"]', wait: 10)
  end

  scenario "creates profile and redirects to show page" do
    visit new_company_customer_profile_path(company)
    fill_in "customer_profile[name]", with: "Profile 1"
    fill_in "customer_profile[customer_id]", with: customer.id
    page.execute_script("document.querySelector('select[name=\"customer_profile[business_type]\"]').value = 'general'")
    click_button "Save Customer Profile"
    expect(page).to have_current_path(/\/customer_profiles\//, wait: 10)
    expect(page).to have_content("Profile 1", wait: 10)
    expect(CustomerProfile.find_by(name: "Profile 1")).to be_present
  end
end
