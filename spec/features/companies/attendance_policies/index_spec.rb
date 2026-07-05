require "rails_helper"

RSpec.feature "Companies::AttendancePolicies Management", type: :feature, js: true do
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

  scenario "index page loads and displays attendance policies table" do
    visit company_attendance_policies_path(company)
    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_selector("th", text: "Branch")
    expect(page).to have_selector("tbody tr")
  end

  scenario "branch name links to show page" do
    visit company_attendance_policies_path(company)
    expect(page).to have_selector("table", wait: 10)
    link = find("a[href*='/attendance_policies/#{attendance_policy.id}']", match: :first)
    expect(link).to be_present
  end

  scenario "edit button links to edit page" do
    visit company_attendance_policies_path(company)
    expect(page).to have_selector("table", wait: 10)
    edit_link = find("a[href*='/attendance_policies/#{attendance_policy.id}/edit']", match: :first)
    expect(edit_link).to be_present
  end

  scenario "add button links to new page" do
    visit company_attendance_policies_path(company)
    expect(page).to have_link(href: new_company_attendance_policy_path(company), wait: 10)
  end
end
