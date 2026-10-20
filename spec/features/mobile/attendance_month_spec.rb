require "rails_helper"

RSpec.feature "Mobile Attendance Month", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:user) { company.user }
  let(:employee) { company.employees.find_by(user: user) }
  let!(:attendance_month) do
    AttendanceMonth.create!(company: company, employee: employee, month: Date.current.beginning_of_month, total_work_minutes: 9600, total_present_days: 20, total_absent_days: 2)
  end
  let!(:attendance_day) do
    AttendanceDay.create!(company: company, employee: employee, attendance_date: Date.current.beginning_of_month + 2.days, attendance_status: :present, total_seconds_worked: 28_800)
  end

  scenario "shows attendance month details" do
    sign_in(user)
    visit mobile_attendance_month_path

    expect(page).to have_content("Attendance Month")
    expect(page).to have_content(employee.name)
    expect(page).to have_content("9600")
    expect(page).to have_content(attendance_day.attendance_date.strftime("%d %b"))
  end

  scenario "has back to home link" do
    sign_in(user)
    visit mobile_attendance_month_path

    expect(page).to have_link("Back to Home", href: mobile_home_path)
    click_link "Back to Home"
    expect(page).to have_content("Welcome, #{user.name}")
  end

  scenario "redirects to sign-in for unauthenticated user" do
    visit mobile_attendance_month_path
    expect(page).to have_current_path(root_path)
  end
end