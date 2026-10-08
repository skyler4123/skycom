require "rails_helper"

RSpec.feature "Companies::AttendanceRequests Management", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:employee) { create(:employee, company: company) }

  let!(:attendance_request) do
    AttendanceRequest.create!(
      company: company, employee: employee,
      attendance_date: Date.yesterday,
      check_in: Time.zone.parse("#{Date.yesterday} 09:00"),
      check_out: Time.zone.parse("#{Date.yesterday} 17:00"),
      reason: "Field work - no GPS"
    )
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

  scenario "index page loads and displays attendance requests table" do
    visit company_attendance_requests_path(company)
    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_selector("th", text: "Employee")
    expect(page).to have_content("Field work - no GPS")
  end

  scenario "manager approves a pending request and day appears" do
    visit company_attendance_requests_path(company)
    expect(page).to have_selector("table", wait: 10)

    click_button "Approve"
    expect(page).to have_content("Approved", wait: 10)
    expect(AttendanceDay.find_by(company: company, employee: employee, attendance_date: Date.yesterday)).to be_present
  end
end
