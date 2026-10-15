require "rails_helper"

RSpec.feature "Companies::EmployeeProfiles Edit", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:employee) { create(:employee, company: company) }
  let!(:profile) { Seed::EmployeeProfileService.create(company: company, employee: employee, name: "Editable Profile", description: "Original") }

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
        employee_profile: {
          business_types: [ { name: "General", value: "general" }, { name: "Special", value: "special" } ],
          lifecycle_statuses: [],
          workflow_statuses: [ { name: "Draft", value: "draft" }, { name: "Pending", value: "pending" }, { name: "Confirmed", value: "confirmed" } ]
        }
      },
      employees: []
    }
    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "renders edit form" do
    visit edit_company_employee_profile_path(company, profile)
    expect(page).to have_selector('input[name="employee_profile[name]"]', wait: 10)
  end

  scenario "updates profile and redirects to show page" do
    visit edit_company_employee_profile_path(company, profile)
    expect(page).to have_selector('input[name="employee_profile[name]"]', wait: 10)
    fill_in "employee_profile[name]", with: "Updated Profile Name"
    click_button "Save Changes"
    expect(page).to have_current_path(company_employee_profile_path(company, profile), wait: 10)
    expect(page).to have_content("Updated Profile Name", wait: 10)
    expect(profile.reload.name).to eq("Updated Profile Name")
  end

  scenario "handles validation error" do
    visit edit_company_employee_profile_path(company, profile)
    expect(page).to have_selector('input[name="employee_profile[name]"]', wait: 10)
    fill_in "employee_profile[name]", with: ""
    click_button "Save Changes"
    expect(page).to have_content("can't be blank", wait: 10)
    expect(page).to have_current_path(edit_company_employee_profile_path(company, profile), wait: 10)
  end
end
