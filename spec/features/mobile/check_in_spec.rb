# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Mobile Check In", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:user) { company.user }
  let(:branch) { create(:branch, company: company) }
  let!(:employee) { company.employees.find_by(user: user).tap { |record| record.update!(branch: branch) } }

  scenario "creates attendance log and shows success notice" do
    sign_in(user)
    visit mobile_company_home_path(company)

    click_button "Clock In"

    expect(page).to have_content("Checked in successfully")
    expect(AttendanceLog.count).to eq(1)
  end

  scenario "records check_in log type with correct employee" do
    sign_in(user)
    visit mobile_company_home_path(company)

    click_button "Clock In"

    expect(page).to have_content("Checked in successfully")

    log = AttendanceLog.last
    expect(log.log_type).to eq("check_in")
    expect(log.employee_id).to eq(employee.id)
    expect(log.company_id).to eq(company.id)
  end

  scenario "allows multiple check-ins and shows every time" do
    sign_in(user)
    visit mobile_company_home_path(company)

    click_button "Clock In"

    expect(page).to have_content("Checked in successfully")
    expect(page).to have_button("Check In Again")

    click_button "Check In Again"

    expect(page).to have_content("Checked in successfully")
    expect(page).to have_button("Check In Again")
    expect(page).to have_content(/today's check-ins/i)
    expect(page).to have_css("[data-check-in-time]", count: 2)
    expect(AttendanceLog.where(employee: employee, log_type: :check_in).count).to eq(2)
  end

  scenario "uses the company's local day and timezone for check-ins" do
    company.update!(timezone: :plus_7)
    sign_in(user)

    company_midnight = Time.current.getlocal(7 * 3600).beginning_of_day
    AttendanceLog.create!(
      company: company,
      employee: employee,
      log_type: :check_in,
      logged_at: company_midnight
    )

    visit mobile_company_home_path(company)

    expect(page).to have_css("[data-check-in-status='checked_in']")
    expect(page).to have_content(/today's check-ins/i)
    expect(page).to have_content("12:00 AM")
  end

  scenario "redirects an unauthorized employee's check-in attempt" do
    unauthorized_user = create(:user)
    create(:employee, user: unauthorized_user, company: company)

    sign_in(unauthorized_user)
    visit mobile_company_home_path(company)

    if page.has_button?("Clock In")
      click_button "Clock In"
    end

    expect(AttendanceLog.count).to eq(0)
    expect(page).to have_content("not authorized")
  end

  scenario "redirects to sign-in for unauthenticated user" do
    visit mobile_company_home_path(company)
    expect(page).to have_current_path(mobile_sign_in_path)
  end
end
