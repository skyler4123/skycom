require "rails_helper"

RSpec.feature "Companies::EmployeeSubprofiles Edit", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:employee) { create(:employee, company: company) }
  let(:profile_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "employee_profiles") }
  let(:profile) { Seed::EmployeeProfileService.create(company: company, employee: employee, category: profile_category, name: "Profile 1") }
  let!(:sub) { Seed::EmployeeSubprofileService.create(company: company, employee: employee, employee_profile: profile, name: "Editable Sub") }

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
      enums: { employee_subprofile: { business_types: [ { name: "General", value: "general" }, { name: "Special", value: "special" } ], lifecycle_statuses: [], workflow_statuses: [ { name: "Draft", value: "draft" } ] } },
      employees: []
    }
    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "updates subprofile" do
    visit edit_company_employee_subprofile_path(company, sub)
    expect(page).to have_selector('input[name="employee_subprofile[name]"]', wait: 10)
    fill_in "employee_subprofile[name]", with: "Updated Sub"
    click_button "Save Changes"
    expect(page).to have_current_path(company_employee_subprofile_path(company, sub), wait: 10)
    expect(page).to have_content("Updated Sub", wait: 10)
    expect(sub.reload.name).to eq("Updated Sub")
  end
end
