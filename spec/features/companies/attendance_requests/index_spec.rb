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

  scenario "filters the queue by status" do
    AttendanceRequest.create!(
      company: company, employee: employee,
      attendance_date: Date.yesterday - 2.days,
      check_in: Time.zone.parse("#{Date.yesterday - 2.days} 09:00"),
      check_out: Time.zone.parse("#{Date.yesterday - 2.days} 17:00"),
      reason: "Remote work audit visit"
    ).update!(status: :approved)

    visit company_attendance_requests_path(company)
    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_content("Field work - no GPS")
    expect(page).to have_content("Remote work audit visit")

    select "Pending", from: "status"
    click_button "Search"

    expect(page).to have_current_path(/status=pending/, wait: 10)
    expect(page).to have_content("Field work - no GPS")
    expect(page).not_to have_content("Remote work audit visit")
  end

  scenario "manager approves a pending request and day appears" do
    visit company_attendance_requests_path(company)
    expect(page).to have_selector("table", wait: 10)

    click_button "Approve"
    expect(page).to have_content("Approved", wait: 10)
    expect(AttendanceDay.find_by(company: company, employee: employee, attendance_date: Date.yesterday)).to be_present
  end

  scenario "filters by employee name, business type and date range" do
    alice = create(:employee, company: company).tap { |e| e.update!(name: "Alice Wonderland") }
    bob = create(:employee, company: company).tap { |e| e.update!(name: "Bob Builder") }
    AttendanceRequest.create!(
      company: company, employee: alice,
      attendance_date: Date.parse("2026-09-10"),
      check_in: Time.zone.parse("2026-09-10 09:00"),
      check_out: Time.zone.parse("2026-09-10 17:00"),
      reason: "Alice field work", business_type: :field_work
    )
    AttendanceRequest.create!(
      company: company, employee: bob,
      attendance_date: Date.parse("2026-09-12"),
      check_in: Time.zone.parse("2026-09-12 09:00"),
      reason: "Bob remote work", business_type: :remote_work
    )

    visit company_attendance_requests_path(company)
    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_content("Alice field work")
    expect(page).to have_content("Bob remote work")

    fill_in "employee_name", with: "bob"
    select "Remote work", from: "business_type"
    page.execute_script("document.querySelector(\"input[name='from']\").value = '2026-09-11'")
    page.execute_script("document.querySelector(\"input[name='to']\").value = '2026-09-13'")
    click_button "Search"

    expect(page).to have_current_path(/employee_name=bob/, wait: 10)
    expect(page).to have_content("Bob remote work")
    expect(page).not_to have_content("Alice field work")
  end
end
