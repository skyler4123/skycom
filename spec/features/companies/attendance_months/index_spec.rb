require "rails_helper"

RSpec.feature "Companies::AttendanceMonths Management", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:employee) { create(:employee, company: company) }

  let!(:attendance_month) do
    create(:attendance_month, company: company, employee: employee)
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

  scenario "index page loads and displays attendance months table" do
    visit company_attendance_months_path(company)
    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_selector("th", text: "Employee")
    expect(page).to have_selector("th", text: "Month")
    expect(page).to have_selector("tbody tr")
  end

  scenario "employee name links to show page" do
    visit company_attendance_months_path(company)
    expect(page).to have_selector("table", wait: 10)
    link = find("a[href*='/attendance_months/#{attendance_month.id}']", match: :first)
    expect(link).to be_present
  end

  scenario "filters by employee name and month range" do
    alice = create(:employee, company: company).tap { |e| e.update!(name: "Alice Wonderland") }
    bob = create(:employee, company: company).tap { |e| e.update!(name: "Bob Builder") }
    AttendanceMonth.create!(company: company, employee: alice, month: Date.parse("2026-08-01"), total_absent_days: 0, total_deficit_minutes: 0)
    AttendanceMonth.create!(company: company, employee: bob, month: Date.parse("2026-09-01"), total_absent_days: 5, total_deficit_minutes: 300)

    visit company_attendance_months_path(company)
    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_content("Alice Wonderland")
    expect(page).to have_content("Bob Builder")

    fill_in "employee_name", with: "bob"
    page.execute_script("document.querySelector(\"input[name='from']\").value = '2026-09-01'")
    page.execute_script("document.querySelector(\"input[name='to']\").value = '2026-09-30'")
    click_button "Search"

    expect(page).to have_current_path(/employee_name=bob/, wait: 10)
    expect(page).to have_content("Bob Builder")
    expect(page).not_to have_content("Alice Wonderland")
  end

  scenario "filters by min absent days and min deficit minutes" do
    alice = create(:employee, company: company).tap { |e| e.update!(name: "Alice Wonderland") }
    bob = create(:employee, company: company).tap { |e| e.update!(name: "Bob Builder") }
    AttendanceMonth.create!(company: company, employee: alice, month: Date.parse("2026-09-01"), total_absent_days: 0, total_deficit_minutes: 0)
    AttendanceMonth.create!(company: company, employee: bob, month: Date.parse("2026-09-01"), total_absent_days: 5, total_deficit_minutes: 300)

    visit company_attendance_months_path(company)
    expect(page).to have_selector("table", wait: 10)

    fill_in "min_absent_days", with: "3"
    fill_in "min_deficit_minutes", with: "100"
    click_button "Search"

    expect(page).to have_current_path(/min_absent_days=3/, wait: 10)
    expect(page).to have_content("Bob Builder")
    expect(page).not_to have_content("Alice Wonderland")
  end
end
