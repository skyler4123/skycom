require "rails_helper"

RSpec.feature "Companies::Departments Edit", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }

  let!(:department) { create(:department, company: company) }

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
          workflow_statuses: [
            { name: "Active", value: "active" },
            { name: "Inactive", value: "inactive" },
            { name: "Draft", value: "draft" }
          ]
        }
      },
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "renders edit form with department name and type fields" do
    visit edit_company_department_path(company, department)

    expect(page).to have_selector('input[name="department[name]"]', wait: 10)
    expect(page).to have_selector('select[name="department[business_type]"]', wait: 10)
    expect(page).to have_selector('select[name="department[workflow_status]"]', wait: 10)
  end

  scenario "updates department and redirects to show page" do
    visit edit_company_department_path(company, department)

    expect(page).to have_selector('input[name="department[name]"]', wait: 10)
    fill_in 'department[name]', with: 'Updated Department Name'

    click_button "Save Changes"

    expect(page).to have_content('Updated Department Name', wait: 10)

    department.reload
    expect(department.name).to eq("Updated Department Name")
    expect(page).to have_current_path(company_department_path(company, department), wait: 10)
  end

  scenario "updates description" do
    visit edit_company_department_path(company, department)

    fill_in 'department[description]', with: 'Updated description text'

    click_button "Save Changes"

    expect(page).to have_content('Updated description text', wait: 10)

    department.reload
    expect(department.description).to eq('Updated description text')
  end
end
