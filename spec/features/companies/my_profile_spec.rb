require "rails_helper"

RSpec.feature "My Profile", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:employee) { company.employees.find_by(user: owner) }
  let(:branch) { employee.branch }

  let!(:attendance_month_current) do
    create(:attendance_month, company: company, employee: employee)
  end

  let!(:attendance_month_other) do
    AttendanceMonth.create!(company: company, employee: employee, month: 1.month.ago.beginning_of_month, total_work_minutes: 1200, total_present_days: 5, total_absent_days: 1)
  end

  let!(:attendance_day) do
    AttendanceDay.create!(company: company, employee: employee, attendance_date: attendance_month_current.month.to_date + 2.days, attendance_status: :present, total_seconds_worked: 28_800)
  end

  let!(:payroll_current) do
    create(:payroll, company: company, employee: employee, month: Date.current.beginning_of_month)
  end

  let!(:payroll_other) do
    create(:payroll, company: company, employee: employee, month: 1.month.ago.beginning_of_month, status: :paid)
  end

  def seed_client_cache!
    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
      "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
      "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
      "branches" => [],
      "departments" => [],
      "roles" => []
    )

    payload = {
      user: JSON.parse(owner.to_json),
      companies: [ company_data ],
      enums: {},
      employees: [ JSON.parse(employee.to_json) ]
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
    page.execute_script("localStorage.setItem('open-cache-sidebar', 'sidebar')")
  end

  def avatar_jpeg
    Rails.root.join("faker/images/randoms/685-200x200.jpg")
  end

  def oversized_jpeg
    file = Tempfile.new([ "oversized_avatar", ".jpg" ])
    file.write("a" * 600.kilobytes)
    file.rewind
    file
  end

  before do
    sign_in(owner)
    seed_client_cache!
  end

  scenario "sidebar renders My Profile group with items" do
    visit company_dashboards_path(company)

    find("details[data-sidebar-group='my_profile'] summary", visible: :all).click
    within("details[data-sidebar-group='my_profile']", visible: :all) do
      expect(page).to have_link("Employee", visible: :all, wait: 10)
      expect(page).to have_link("Attendance", visible: :all)
      expect(page).to have_link("Payroll", visible: :all)
    end
  end

  scenario "Employee item navigates to current employee show page" do
    visit company_dashboards_path(company)
    find("details[data-sidebar-group='my_profile'] summary", visible: :all).click
    click_link "Employee", match: :first

    expect(page).to have_current_path(company_employee_path(company, employee), wait: 10)
    expect(page).to have_content(employee.name, wait: 10)
  end

  scenario "avatar Profile link navigates to current employee show page" do
    visit company_dashboards_path(company)

    find('[data-controller="avatar"]').click
    click_link "Profile"

    expect(page).to have_current_path(company_employee_path(company, employee), wait: 10)
    expect(page).to have_content(employee.name, wait: 10)
  end

  scenario "Employee profile shows the linked user account" do
    visit company_employee_path(company, employee)

    expect(page).to have_content(/User Account/i, wait: 10)
    expect(page).to have_content("Work Email", wait: 10)
    expect(page).to have_content(owner.email, wait: 10)
    expect(page).to have_content("Company Owner", wait: 10)
    expect(page.text.downcase.index("user account")).to be < page.text.downcase.index("work email")
  end

  scenario "own profile lets the user change their avatar" do
    visit company_employee_path(company, employee)

    find("input[type='file']", visible: :all).attach_file(avatar_jpeg, make_visible: true)

    expect(page).to have_content("Avatar updated!", wait: 10)
    expect(page).to have_selector("img[src*='/rails/active_storage/']", wait: 10)
  end

  scenario "another employee's profile keeps the avatar read-only" do
    other = create(:employee, company: company)
    visit company_employee_path(company, other)

    expect(page).to have_content(other.name, wait: 10)
    expect(page).not_to have_selector("input[type='file']", visible: :all)
  end

  scenario "rejected avatar upload keeps the previous avatar" do
    oversized = oversized_jpeg

    visit company_employee_path(company, employee)
    find("input[type='file']", visible: :all).attach_file(oversized.path, make_visible: true)

    expect(page).to have_content("is too big", wait: 10)
    expect(page).not_to have_selector("img[src*='/rails/active_storage/']")
  ensure
    oversized&.close!
  end

  scenario "Attendance item shows current month and month dropdown" do
    visit company_dashboards_path(company)
    find("details[data-sidebar-group='my_profile'] summary", visible: :all).click
    click_link "Attendance", match: :first

    expect(page).to have_current_path(/attendance_months\/my/, wait: 10)
    expect(page).to have_content(attendance_month_current.total_work_minutes.to_s, wait: 10)
    expect(page).to have_selector("select", wait: 10)
  end

  scenario "Attendance page shows daily breakdown" do
    visit my_company_attendance_months_path(company)
    expect(page).to have_content("Daily Breakdown", wait: 10)
    expect(page).to have_selector("tbody tr", wait: 10)
    expect(page).to have_content(attendance_day.attendance_date.day.to_s, wait: 10)
  end

  scenario "Attendance month dropdown switches months" do
    visit my_company_attendance_months_path(company)
    find("select").select(attendance_month_other.month.strftime("%B %Y"))
    expect(page).to have_content(attendance_month_other.total_work_minutes.to_s, wait: 10)
  end

  scenario "Payroll item shows current payroll month and dropdown" do
    visit company_dashboards_path(company)
    find("details[data-sidebar-group='my_profile'] summary", visible: :all).click
    click_link "Payroll", match: :first

    expect(page).to have_current_path(/payroll\/my/, wait: 10)
    expect(page).to have_content(payroll_current.employee.name, wait: 10)
    expect(page).to have_selector("select", wait: 10)
  end

  scenario "Payroll month dropdown switches months" do
    visit company_payroll_my_path(company)
    find("select").select(payroll_other.month.strftime("%B %Y"))
    expect(page).to have_content(payroll_other.month.to_date.strftime('%B %Y'), wait: 10)
  end
end
