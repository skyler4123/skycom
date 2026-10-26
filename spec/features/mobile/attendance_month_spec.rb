# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Mobile Attendance Month", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:user) { company.user }
  let(:employee) { company.employees.find_by(user: user) }
  let(:day_date) { Date.current.beginning_of_month + 2.days }
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
  let!(:attendance_day) do
    AttendanceDay.create!(
      company: company,
      employee: employee,
      attendance_date: day_date,
      attendance_status: :present,
      total_seconds_worked: 28_800,
      check_in: day_date.in_time_zone.change(hour: 9, min: 0),
      check_out: day_date.in_time_zone.change(hour: 17, min: 0)
    )
  end

  scenario "shows attendance month details" do
    sign_in(user)
    visit mobile_attendance_month_path

    expect(page).to have_content("Attendance")
    expect(page).to have_content(employee.name)
    expect(page).to have_content("Total Worked")
    expect(page).to have_content("160h 00m")
    expect(page).to have_content("20 Days")
    expect(page).to have_content("2 Days")
    expect(page).to have_content(day_date.strftime("%d %B %Y"))
    expect(page).to have_content("Present")
    expect(page).to have_content("09:00 AM")
    expect(page).to have_content("05:00 PM")
    expect(page).to have_content("8h 00m")
  end

  scenario "links to filing a new attendance request" do
    sign_in(user)
    visit mobile_attendance_month_path

    expect(page).to have_link("New Request", href: new_mobile_attendance_request_path)
  end

  scenario "navigates to the previous month" do
    sign_in(user)
    visit mobile_attendance_month_path

    expect(page).to have_selector("a[aria-label='Previous month']")
    find("a[aria-label='Previous month']").click

    expect(page).to have_content((Date.current.beginning_of_month - 1.month).strftime("%B %Y"))
  end

  scenario "shows empty states without attendance records" do
    empty_company = create(:company)
    empty_user = empty_company.user
    sign_in(empty_user)

    visit mobile_attendance_month_path

    expect(page).to have_content("No summary for this month")
    expect(page).to have_content("No daily records for this month yet")
  end

  scenario "redirects to sign-in for unauthenticated user" do
    visit mobile_attendance_month_path
    expect(page).to have_current_path(mobile_sign_in_path)
  end
end
