require "rails_helper"

RSpec.feature "Companies::AttendancePolicies New", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company) }

  before do
    sign_in(owner)

    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => [],
      "table_configs" => [],
      "categories" => [],
      "branches" => [],
      "departments" => [],
      "roles" => []
    )

    payload = {
      user: JSON.parse(owner.to_json),
      companies: [ company_data ],
      enums: {},
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "creates attendance policy and redirects to show page" do
    visit new_company_attendance_policy_path(company)
    expect(page).to have_selector("input[name='attendance_policy[branch_id]']", wait: 10)

    fill_in "attendance_policy[branch_id]", with: branch.id
    fill_in "attendance_policy[latitude]", with: "10.5"
    fill_in "attendance_policy[longitude]", with: "106.5"
    click_button "Save"

    expect(page).to have_content("Attendance Policy", wait: 10)
    record = AttendancePolicy.find_by(latitude: 10.5)
    expect(record).to be_present
    expect(page).to have_current_path(/\/attendance_policies\//, wait: 10)
  end

  scenario "handles validation error" do
    visit new_company_attendance_policy_path(company)
    expect(page).to have_selector("input[name='attendance_policy[branch_id]']", wait: 10)

    fill_in "attendance_policy[branch_id]", with: ""
    click_button "Save"

    expect(page).to have_current_path(new_company_attendance_policy_path(company), wait: 10)
  end
end
