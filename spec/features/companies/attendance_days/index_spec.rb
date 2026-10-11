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

  scenario "filters by employee name" do
    alice = create(:employee, company: company).tap { |e| e.update!(name: "Alice Wonderland") }
    bob = create(:employee, company: company).tap { |e| e.update!(name: "Bob Builder") }
    AttendanceDay.create!(company: company, employee: alice, attendance_date: Date.parse("2026-09-10"), attendance_status: :present, total_seconds_worked: 28_800)
    AttendanceDay.create!(company: company, employee: bob, attendance_date: Date.parse("2026-09-10"), attendance_status: :present, total_seconds_worked: 28_800)

    visit company_attendance_days_path(company)
    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_content("Alice Wonderland")
    expect(page).to have_content("Bob Builder")

    fill_in "employee_name", with: "bob"
    click_button "Search"

    expect(page).to have_current_path(/employee_name=bob/, wait: 10)
    expect(page).to have_content("Bob Builder")
    expect(page).not_to have_content("Alice Wonderland")
  end

  scenario "filters by status and date range" do
    alice = create(:employee, company: company).tap { |e| e.update!(name: "Alice Wonderland") }
    AttendanceDay.create!(company: company, employee: alice, attendance_date: Date.parse("2026-09-10"), attendance_status: :present, total_seconds_worked: 28_800)
    AttendanceDay.create!(company: company, employee: alice, attendance_date: Date.parse("2026-09-12"), attendance_status: :late, total_seconds_worked: 27_000)

    visit company_attendance_days_path(company)
    expect(page).to have_selector("table", wait: 10)

    select "Late", from: "attendance_status"
    page.execute_script("document.querySelector(\"input[name='from']\").value = '2026-09-11'")
    page.execute_script("document.querySelector(\"input[name='to']\").value = '2026-09-13'")
    click_button "Search"

    expect(page).to have_current_path(/attendance_status=late/, wait: 10)
    expect(page).to have_selector("tbody tr", count: 1, wait: 10)
  end
end
