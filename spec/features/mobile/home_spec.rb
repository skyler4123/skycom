# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Mobile Home", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:user) { company.user }
  let!(:employee) { company.employees.find_by(user: user) }

  scenario "shows the dashboard for the signed-in employee" do
    sign_in(user)
    visit mobile_company_home_path(company)

    expect(page).to have_content(user.name.split.first)
    expect(page).to have_content(company.name)
    expect(page).to have_link(href: mobile_company_employee_path(company))
    expect(page).to have_link(href: mobile_company_attendance_month_path(company))
    expect(page).to have_link(href: mobile_company_payroll_path(company))
    expect(page).to have_link(href: new_mobile_company_attendance_request_path(company))
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
    visit mobile_company_home_path(company)

    was_dark = page.evaluate_script("document.documentElement.classList.contains('dark')")
    find("button[aria-label='Toggle dark mode']").click
    expect(page.evaluate_script("document.documentElement.classList.contains('dark')")).to eq(!was_dark)
    find("button[aria-label='Toggle dark mode']").click
    expect(page.evaluate_script("document.documentElement.classList.contains('dark')")).to eq(was_dark)
  end

  scenario "records a check-in and shows the checked-in state" do
    sign_in(user)
    visit mobile_company_home_path(company)

    click_button "Clock In"

    expect(page).to have_content("Checked in successfully")
    expect(page).to have_content("Checked In")
    expect(page).not_to have_button("Clock In")
  end

  scenario "redirects to mobile sign-in for unauthenticated user" do
    visit mobile_company_home_path(company)

    expect(page).to have_current_path(mobile_sign_in_path)
  end
end
