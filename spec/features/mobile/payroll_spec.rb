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
      attendance_month: attendance_month,
      currency: :usd,
      base_amount_cents: 520_000,
      allowance_amount_cents: 42_000,
      overtime_amount_cents: 34_250,
      gross_amount_cents: 596_250,
      tax_amount_cents: 59_625,
      deduction_amount_cents: 50_085,
      net_amount_cents: 486_540
    )
  end

  def unlock_payroll(company, password: "Password@1234")
    visit mobile_company_payroll_unlock_path(company)
    fill_in "Password", with: password
    click_button "Open Payroll"
  end

  scenario "asks for the password before showing payroll" do
    sign_in(user)
    visit mobile_company_employee_path(company)

    click_link "Payroll"

    expect(page).to have_current_path(mobile_company_payroll_unlock_path(company))
    expect(page).to have_content("Payroll is private")
    expect(page).not_to have_content("$4,865.40")

    fill_in "Password", with: "Password@1234"
    click_button "Open Payroll"

    expect(page).to have_current_path(mobile_company_payroll_path(company))
    expect(page).to have_content("$4,865.40")
  end

  scenario "rejects an incorrect password" do
    sign_in(user)
    visit mobile_company_payroll_unlock_path(company)

    fill_in "Password", with: "WrongPassword@1234"
    click_button "Open Payroll"

    expect(page).to have_current_path(mobile_company_payroll_unlock_path(company))
    expect(page).to have_content("Incorrect password")
    expect(page).not_to have_content("$4,865.40")
  end

  scenario "asks again every time payroll is opened from Profile" do
    sign_in(user)
    visit mobile_company_employee_path(company)

    click_link "Payroll"
    fill_in "Password", with: "Password@1234"
    click_button "Open Payroll"
    expect(page).to have_content("$4,865.40")

    visit mobile_company_employee_path(company)
    click_link "Payroll"

    expect(page).to have_current_path(mobile_company_payroll_unlock_path(company))
    expect(page).not_to have_content("$4,865.40")
  end

  scenario "shows the payroll overview for the current month" do
    sign_in(user)
    unlock_payroll(company)

    expect(page).to have_content("Payroll")
    expect(page).to have_content(employee.name)
    expect(page).to have_content("Paid")
    expect(page).to have_content("$5,962.50")
    expect(page).to have_content("$4,865.40")
    expect(page).to have_content("$5,200.00")
    expect(page).not_to have_content("Preview layout")
    expect(page).not_to have_content("Sample")
    expect(find("a[aria-label='Go back']")["data-turbo-action"]).to eq("replace")
  end

  scenario "links to the attendance timesheet" do
    sign_in(user)
    unlock_payroll(company)

    expect(page).to have_link("View Timesheet", href: mobile_company_attendance_month_path(company, month: Date.current.beginning_of_month.strftime("%Y-%m")))
  end

  scenario "switches pay period from the selector" do
    sign_in(user)
    unlock_payroll(company)

    previous_month = Date.current.beginning_of_month - 1.month
    find("select[aria-label='Pay period']").select(previous_month.strftime("%B %Y"))

    expect(page).to have_current_path(mobile_company_payroll_path(company, month: previous_month.strftime("%Y-%m")))
  end

  scenario "does not render a working payslip download" do
    sign_in(user)
    unlock_payroll(company)

    expect(page).to have_button("Draft Payslip", disabled: true)
  end

  scenario "shows empty state without payroll data" do
    empty_company = create(:company)
    empty_user = empty_company.user
    sign_in(empty_user)

    unlock_payroll(empty_company)

    expect(page).to have_content("No payroll data for this month.")
  end

  scenario "redirects a direct payroll visit to the password gate" do
    sign_in(user)

    visit mobile_company_payroll_path(company)

    expect(page).to have_current_path(mobile_company_payroll_unlock_path(company))
    expect(page).not_to have_content("$4,865.40")
  end

  scenario "redirects to sign-in for unauthenticated user" do
    visit mobile_company_payroll_path(company)
    expect(page).to have_current_path(mobile_sign_in_path)
  end

  scenario "lets any company member reach the payroll password gate" do
    member_user = create(:user)
    create(:employee, user: member_user, company: company)

    sign_in(member_user)
    visit mobile_company_payroll_path(company)

    expect(page).to have_current_path(mobile_company_payroll_unlock_path(company))
    expect(page).to have_content("Payroll is private")
  end
end
