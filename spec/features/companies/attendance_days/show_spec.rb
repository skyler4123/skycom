require "rails_helper"

RSpec.feature "Companies::AttendanceDays Show", type: :feature, js: true do
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

  scenario "displays attendance day details" do
    visit company_attendance_day_path(company, attendance_day)
    expect(page).to have_content(employee.name, wait: 10)
    expect(page).to have_content("Present", wait: 10)
  end

  scenario "has back link to index page" do
    visit company_attendance_day_path(company, attendance_day)
    back_link = find("a[href*='/attendance_days']", match: :first)
    expect(back_link).to be_present
  end
end
