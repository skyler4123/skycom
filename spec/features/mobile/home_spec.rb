# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Mobile Home", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:user) { company.user }
  let!(:employee) { company.employees.find_by(user: user) }

  scenario "shows the dashboard for the signed-in employee" do
    sign_in(user)
    visit mobile_home_path

    expect(page).to have_content(user.name.split.first)
    expect(page).to have_content(company.name)
    expect(page).to have_link(href: mobile_employee_path)
    expect(page).to have_link(href: mobile_attendance_month_path)
    expect(page).to have_link(href: mobile_payroll_path)
    expect(page).to have_link(href: new_mobile_attendance_request_path)
    expect(page).to have_content("Employee Info")
    expect(page).to have_content("Attendance")
    expect(page).to have_content("Payroll")
    expect(page).to have_content("Requests")
    expect(page).to have_button("Clock In")
    expect(page).to have_content("Paid Leave")
    expect(page).to have_content("Sample")
    expect(page).not_to have_content("--:--:--")
  end

  scenario "toggles dark mode from the header" do
    sign_in(user)
    visit mobile_home_path

    was_dark = page.evaluate_script("document.documentElement.classList.contains('dark')")
    find("button[aria-label='Toggle dark mode']").click
    expect(page.evaluate_script("document.documentElement.classList.contains('dark')")).to eq(!was_dark)
    find("button[aria-label='Toggle dark mode']").click
    expect(page.evaluate_script("document.documentElement.classList.contains('dark')")).to eq(was_dark)
  end

  scenario "records a check-in and shows the checked-in state" do
    sign_in(user)
    visit mobile_home_path

    click_button "Clock In"

    expect(page).to have_content("Checked in successfully")
    expect(page).to have_content("Checked In")
    expect(page).not_to have_button("Clock In")
  end

  scenario "does not offer check-in without an employee record" do
    other_user = create(:user)
    sign_in(other_user)

    visit mobile_home_path

    expect(page).to have_content("No employee profile linked")
    expect(page).to have_button("Sign Out")
    expect(page).not_to have_button("Clock In")
  end

  scenario "redirects to mobile sign-in for unauthenticated user" do
    visit mobile_home_path

    expect(page).to have_current_path(mobile_sign_in_path)
  end
end
