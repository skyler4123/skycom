require "rails_helper"

RSpec.feature "Companies::AttendanceDays Management", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:employee) { create(:employee, company: company) }

  let!(:attendance_day) do
    create(:attendance_day, company: company, employee: employee)
  end

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

  scenario "index page loads and displays attendance days table" do
    visit company_attendance_days_path(company)
    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_selector("th", text: "Employee")
    expect(page).to have_selector("th", text: "Date")
    expect(page).to have_selector("tbody tr")
  end

  scenario "employee name links to show page" do
    visit company_attendance_days_path(company)
    expect(page).to have_selector("table", wait: 10)
    link = find("a[href*='/attendance_days/#{attendance_day.id}']", match: :first)
    expect(link).to be_present
  end
end
