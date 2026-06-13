require "rails_helper"

RSpec.feature "Companies::Departments New", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
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
      enums: {
        department: {
          business_types: [
            { name: "Sales", value: "sales" },
            { name: "Marketing", value: "marketing" },
            { name: "Operations", value: "operations" }
          ],
          lifecycle_statuses: [],
          workflow_statuses: []
        }
      },
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "renders new department form with name and type fields" do
    visit new_company_department_path(company)

    expect(page).to have_selector('input[name="department[name]"]', wait: 10)
    expect(page).to have_selector('select[name="department[business_type]"]', wait: 10)
  end

  scenario "creates department and redirects to show page" do
    visit new_company_department_path(company)

    fill_in 'department[name]', with: 'New Test Department'
    select 'Operations', from: 'department[business_type]'

    click_button "Save Department"

    expect(page).to have_content('New Test Department', wait: 10)

    department_record = Department.find_by(name: "New Test Department")
    expect(department_record).to be_present
    expect(page).to have_current_path(company_department_path(company, department_record), wait: 10)
  end

  scenario "creates department with email" do
    visit new_company_department_path(company)

    fill_in 'department[name]', with: 'Department With Email'
    fill_in 'department[email]', with: 'dept@example.com'

    click_button "Save Department"

    expect(page).to have_content('Department With Email', wait: 10)

    department_record = Department.find_by(name: "Department With Email")
    expect(department_record).to be_present
    expect(department_record.email).to eq('dept@example.com')
  end
end
