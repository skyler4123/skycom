require "rails_helper"

RSpec.feature "Companies::AttendanceLogs Management", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:employee) { create(:employee, company: company) }

  let!(:attendance_log) do
    create(:attendance_log, company: company, employee: employee)
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

  scenario "index page loads and displays attendance logs table" do
    visit company_attendance_logs_path(company)
    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_selector("th", text: "Employee")
    expect(page).to have_selector("tbody tr")
  end

  scenario "employee name links to show page" do
    visit company_attendance_logs_path(company)
    expect(page).to have_selector("table", wait: 10)
    link = find("a[href*='/attendance_logs/#{attendance_log.id}']", match: :first)
    expect(link).to be_present
  end

  scenario "filters by employee name" do
    alice = create(:employee, company: company).tap { |e| e.update!(name: "Alice Wonderland") }
    bob = create(:employee, company: company).tap { |e| e.update!(name: "Bob Builder") }
    AttendanceLog.create!(company: company, employee: alice, log_type: :check_in, logged_at: Time.zone.parse("2026-09-10 09:00"))
    AttendanceLog.create!(company: company, employee: bob, log_type: :check_in, logged_at: Time.zone.parse("2026-09-10 09:00"))

    visit company_attendance_logs_path(company)
    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_content("Alice Wonderland")
    expect(page).to have_content("Bob Builder")

    fill_in "employee_name", with: "alice"
    click_button "Search"

    expect(page).to have_current_path(/employee_name=alice/, wait: 10)
    expect(page).to have_content("Alice Wonderland")
    expect(page).not_to have_content("Bob Builder")
  end

  scenario "filters by log type and date range" do
    alice = create(:employee, company: company).tap { |e| e.update!(name: "Alice Wonderland") }
    AttendanceLog.create!(company: company, employee: alice, log_type: :check_in, logged_at: Time.zone.parse("2026-09-10 09:00"))
    AttendanceLog.create!(company: company, employee: alice, log_type: :check_out, logged_at: Time.zone.parse("2026-09-12 18:00"))

    visit company_attendance_logs_path(company)
    expect(page).to have_selector("table", wait: 10)

    select "Check out", from: "log_type"
    page.execute_script("document.querySelector(\"input[name='from']\").value = '2026-09-11'")
    page.execute_script("document.querySelector(\"input[name='to']\").value = '2026-09-13'")
    click_button "Search"

    expect(page).to have_current_path(/log_type=check_out/, wait: 10)
    expect(page).to have_selector("tbody tr", count: 1, wait: 10)
  end
end
