# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Mobile Payroll", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:user) { company.user }
  let(:employee) { company.employees.find_by(user: user) }
  let!(:attendance_month) do
    AttendanceMonth.create!(
      company: company,
      employee: employee,
      month: Date.current.beginning_of_month,
      total_work_minutes: 9600,
      total_present_days: 20,
      total_absent_days: 2,
      total_records: 22,
      total_overtime_minutes: 270
    )
  end
  let!(:payroll) do
    create(
      :payroll,
      company: company,
      employee: employee,
      month: Date.current.beginning_of_month,
      status: :paid,
      attendance_month: attendance_month
    )
  end

  scenario "shows the payroll overview for the current month" do
    sign_in(user)
    visit mobile_company_payroll_path(company)

    expect(page).to have_content("Payroll")
    expect(page).to have_content(employee.name)
    expect(page).to have_content("Paid")
    expect(page).to have_content("Preview layout")
    expect(page).to have_content("$4,862.50")
    expect(page).to have_content("Sample")
  end

  scenario "links to the attendance timesheet" do
    sign_in(user)
    visit mobile_company_payroll_path(company)

    expect(page).to have_link("View Timesheet", href: mobile_company_attendance_month_path(company, month: Date.current.beginning_of_month.strftime("%Y-%m")))
  end

  scenario "switches pay period from the selector" do
    sign_in(user)
    visit mobile_company_payroll_path(company)

    previous_month = Date.current.beginning_of_month - 1.month
    find("select[aria-label='Pay period']").select(previous_month.strftime("%B %Y"))

    expect(page).to have_current_path(mobile_company_payroll_path(company, month: previous_month.strftime("%Y-%m")))
  end

  scenario "does not render a working payslip download" do
    sign_in(user)
    visit mobile_company_payroll_path(company)

    expect(page).to have_button("Draft Payslip", disabled: true)
  end

  scenario "shows empty state without payroll data" do
    empty_company = create(:company)
    empty_user = empty_company.user
    sign_in(empty_user)

    visit mobile_company_payroll_path(empty_company)

    expect(page).to have_content("No payroll data for this month.")
  end

  scenario "redirects to sign-in for unauthenticated user" do
    visit mobile_company_payroll_path(company)
    expect(page).to have_current_path(mobile_sign_in_path)
  end

  scenario "redirects an unauthorized employee to home" do
    unauthorized_user = create(:user)
    create(:employee, user: unauthorized_user, company: company)

    sign_in(unauthorized_user)
    visit mobile_company_payroll_path(company)

    expect(page).to have_current_path(mobile_company_home_path(company))
    expect(page).to have_content("not authorized")
  end
end
