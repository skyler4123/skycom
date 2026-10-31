# frozen_string_literal: true

require "rails_helper"

# Mobile dark mode is global: Tailwind v4 class strategy keyed off
# `<html class="dark">`, toggled by `mobile--theme` and persisted in
# `localStorage["darkmode"]` (same key as desktop). Regression coverage for
# consistency across mobile screens / Turbo navigations.
RSpec.feature "Mobile dark mode", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:user) { company.user }
  let!(:employee) { company.employees.find_by(user: user) }

  before do
    sign_in(user)
  end

  def html_dark?
    page.evaluate_script("document.documentElement.classList.contains('dark')")
  end

  scenario "toggle persists to localStorage and html class" do
    visit mobile_company_home_path(company)
    # Start light
    page.execute_script("localStorage.setItem('darkmode', 'false')")
    page.execute_script("document.documentElement.classList.remove('dark')")
    expect(html_dark?).to be(false)

    find("button[aria-label='Toggle dark mode']").click
    expect(page.evaluate_script("localStorage.getItem('darkmode')")).to eq("true")
    expect(html_dark?).to be(true)

    find("button[aria-label='Toggle dark mode']").click
    expect(page.evaluate_script("localStorage.getItem('darkmode')")).to eq("false")
    expect(html_dark?).to be(false)
  end

  scenario "dark mode survives full reload" do
    page.execute_script("localStorage.setItem('darkmode', 'true')")
    visit mobile_company_home_path(company)

    expect(page).to have_selector("header", wait: 10)
    expect(html_dark?).to be(true)
  end

  scenario "dark mode stays consistent across mobile screens" do
    visit mobile_company_home_path(company)

    # Start light, then toggle dark on Home.
    page.execute_script("localStorage.setItem('darkmode', 'false')")
    page.execute_script("document.documentElement.classList.remove('dark')")
    find("button[aria-label='Toggle dark mode']").click
    expect(html_dark?).to be(true)
    expect(page.evaluate_script("localStorage.getItem('darkmode')")).to eq("true")

    # Turbo-navigate to Profile and assert the theme holds.
    find("a[href='#{mobile_company_employee_path(company)}']", match: :first).click
    expect(page).to have_css("header h1", text: "Profile", wait: 10)
    expect(html_dark?).to be(true)
    expect(page.evaluate_script("localStorage.getItem('darkmode')")).to eq("true")

    # Turbo-navigate to Operations and assert again.
    visit mobile_company_operations_path(company)
    expect(page).to have_selector("header", wait: 10)
    expect(html_dark?).to be(true)
    expect(page.evaluate_script("localStorage.getItem('darkmode')")).to eq("true")
  end

  scenario "dark mode holds across all mobile pages" do
    page.execute_script("localStorage.setItem('darkmode', 'true')")

    paths = [
      mobile_company_home_path(company),
      mobile_company_notifications_path(company),
      mobile_company_employee_path(company),
      mobile_company_attendance_month_path(company),
      mobile_company_operations_path(company),
      mobile_company_payroll_unlock_path(company),
      new_mobile_company_attendance_request_path(company)
    ]

    paths.each do |path|
      visit path
      expect(page).to have_selector("header", wait: 10)
      expect(html_dark?).to(be(true), "expected dark mode on #{path}")
    end
  end
end
