require "rails_helper"

RSpec.feature "Companies::EmployeeSubprofiles New", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:employee) { create(:employee, company: company) }
  let(:profile_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "employee_profiles") }
  let(:profile) { Seed::EmployeeProfileService.create(company: company, employee: employee, category: profile_category, name: "Profile 1") }

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
      enums: { employee_subprofile: { business_types: [ { name: "General", value: "general" }, { name: "Special", value: "special" } ], lifecycle_statuses: [], workflow_statuses: [] } },
      employees: []
    }
    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "creates subprofile and redirects to show" do
    visit new_company_employee_subprofile_path(company)
    fill_in "employee_subprofile[name]", with: "Subprofile 11"
    fill_in "employee_subprofile[employee_id]", with: employee.id
    fill_in "employee_subprofile[employee_profile_id]", with: profile.id
    page.execute_script("document.querySelector('select[name=\"employee_subprofile[business_type]\"]').value = 'general'")
    click_button "Save Employee Subprofile"
    expect(page).to have_current_path(/\/employee_subprofiles\//, wait: 10)
    expect(page).to have_content("Subprofile 11", wait: 10)
    expect(EmployeeSubprofile.find_by(name: "Subprofile 11")).to be_present
  end
end
