require "rails_helper"

RSpec.feature "Companies::EmployeeSubprofiles Management", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:employee) { create(:employee, company: company) }
  let(:profile_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "employee_profiles") }
  let(:profile) { Seed::EmployeeProfileService.create(company: company, employee: employee, category: profile_category, name: "Profile 1") }

  let!(:default_category) do
    Seed::CategoryService.find_or_create_for(company: company, resource_name: "employee_subprofiles")
  end

  let!(:sub) { Seed::EmployeeSubprofileService.create(company: company, employee: employee, employee_profile: profile, category: default_category, name: "Subprofile 11") }
  let!(:sub2) { Seed::EmployeeSubprofileService.create(company: company, employee: employee, employee_profile: profile, category: default_category, name: "Subprofile 12") }

  let!(:default_table_config) do
    default_category.default_property_mapping.table_configs.destroy_all
    TableConfig.create!(
      company: company, category: default_category,
      property_mapping: default_category.default_property_mapping,
      resource_name: "employee_subprofiles",
      metadata: { "columns" => [
        { "key" => "name", "name" => "Subprofile Name", "visible" => true, "align" => "left", "width" => nil },
        { "key" => "code", "name" => "Code", "visible" => true, "align" => "left", "width" => nil },
        { "key" => "business_type", "name" => "Type", "visible" => true, "align" => "center", "width" => nil },
        { "key" => "workflow_status", "name" => "Status", "visible" => true, "align" => "center", "width" => nil }
      ] }
    )
  end

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

  scenario "index page loads and displays subprofiles" do
    visit company_employee_subprofiles_path(company)
    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_content("Subprofile 11")
  end

  scenario "edit button links to edit page" do
    visit company_employee_subprofiles_path(company)
    expect(page).to have_selector("table", wait: 10)
    edit_link = find("a[href*='/employee_subprofiles/#{sub.id}/edit']", match: :first)
    expect(edit_link).to be_present
  end
end
