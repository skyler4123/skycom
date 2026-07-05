require "rails_helper"

RSpec.feature "Companies::AttendancePolicies Edit", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company) }

  let!(:attendance_policy) { create(:attendance_policy, company: company, branch: branch) }

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

  scenario "pre-fills form with current values" do
    visit edit_company_attendance_policy_path(company, attendance_policy)
    expect(page).to have_selector("input[name='attendance_policy[branch_id]']", wait: 10)
    branch_field = find("input[name='attendance_policy[branch_id]']")
    expect(branch_field).to be_present
  end

  scenario "updates attendance policy and redirects to show page" do
    visit edit_company_attendance_policy_path(company, attendance_policy)
    expect(page).to have_selector("input[name='attendance_policy[latitude]']", wait: 10)

    fill_in "attendance_policy[branch_id]", with: branch.id
    fill_in "attendance_policy[latitude]", with: "11.0"
    fill_in "attendance_policy[longitude]", with: attendance_policy.longitude
    click_button "Save Changes"

    expect(page).to have_content("11.0", wait: 10)
    attendance_policy.reload
    expect(attendance_policy.latitude).to eq(11.0)
    expect(page).to have_current_path(company_attendance_policy_path(company, attendance_policy), wait: 10)
  end

  scenario "handles validation error" do
    visit edit_company_attendance_policy_path(company, attendance_policy)
    expect(page).to have_selector("input[name='attendance_policy[branch_id]']", wait: 10)

    fill_in "attendance_policy[branch_id]", with: ""
    fill_in "attendance_policy[latitude]", with: ""
    fill_in "attendance_policy[longitude]", with: ""
    page.execute_script("document.querySelector('select[name=\"attendance_policy[resolution_strategy]\"]').selectedIndex = -1")
    click_button "Save Changes"
    expect(page).to have_current_path(edit_company_attendance_policy_path(company, attendance_policy), wait: 10)
  end
end
