# frozen_string_literal: true

require "rails_helper"

# Mobile screens are Shell-First, so the shared client-side translate() layer
# applies exactly as it does on web. The signed-in header owns the EN/VI switch;
# every other screen reads localStorage.languageCode on hydration.
RSpec.feature "Mobile language switch", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:user) { company.user }
  let!(:employee) { company.employees.find_by(user: user) }

  before do
    sign_in(user)
  end

  after do
    begin
      page.execute_script("localStorage.setItem('languageCode', 'en')")
    rescue StandardError
      # The browser may already be closed when a scenario fails early.
    end
  end

  def switch_language(code)
    find("[data-language-switch]", wait: 10).click
    find("[data-language-code-param='#{code}']", wait: 10).click
  end

  scenario "shows the switch before the dark-mode button and switches to Vietnamese" do
    visit mobile_company_home_path(company)

    labels = all("header button[aria-label]").map { |button| button["aria-label"] }
    expect(labels.index("Change language")).to be < labels.index("Toggle dark mode")

    switch_language("vi")

    expect(page).to have_css("header h1", text: "Trang chủ", wait: 10)
    expect(page).to have_content("Thao tác nhanh")
    expect(page).to have_content("Hoạt động hôm nay")
    expect(page.evaluate_script("localStorage.getItem('languageCode')")).to eq("vi")
    expect(find("[data-language-switch]").text).to eq("VI")
    expect(find("button[aria-label='Đổi ngôn ngữ']")).to be_present
  end

  scenario "keeps Vietnamese after a full reload and on another page" do
    page.execute_script("localStorage.setItem('languageCode', 'vi')")
    visit mobile_company_home_path(company)

    expect(page).to have_css("header h1", text: "Trang chủ", wait: 10)

    visit mobile_company_employee_path(company)
    expect(page).to have_css("header h1", text: "Hồ sơ", wait: 10)
    expect(page).to have_content("Tài khoản đăng nhập")
  end

  scenario "switches back to English" do
    page.execute_script("localStorage.setItem('languageCode', 'vi')")
    visit mobile_company_home_path(company)
    expect(page).to have_css("header h1", text: "Trang chủ", wait: 10)

    switch_language("en")

    expect(page).to have_css("header h1", text: "Home", wait: 10)
    expect(page).to have_content("Quick Operations")
    expect(page.evaluate_script("localStorage.getItem('languageCode')")).to eq("en")
  end

  scenario "asks the Android shell to refresh every tab instead of reloading one" do
    visit mobile_company_home_path(company)

    page.execute_script(<<~JS)
      window.SkycomMobile = {
        reloadTabs: function () {
          window.__skycomReloadTabsCalled = true
          return true
        }
      }
    JS

    switch_language("vi")

    expect(page.evaluate_script("window.__skycomReloadTabsCalled")).to be(true)
    expect(page.evaluate_script("localStorage.getItem('languageCode')")).to eq("vi")
    # The native shell owns the refresh; this stub leaves the current DOM alone.
    expect(page).to have_css("header h1", text: "Home")
  end

  scenario "translates dynamic attendance status badges" do
    day_date = Date.current.beginning_of_month + 2.days
    AttendanceMonth.create!(
      company: company,
      employee: employee,
      month: Date.current.beginning_of_month,
      total_work_minutes: 240,
      total_present_days: 1,
      total_absent_days: 0,
      total_records: 1,
      total_overtime_minutes: 0
    )
    AttendanceDay.create!(
      company: company,
      employee: employee,
      attendance_date: day_date,
      attendance_status: :half_day,
      total_seconds_worked: 14_400,
      check_in: day_date.in_time_zone.change(hour: 9, min: 0),
      check_out: day_date.in_time_zone.change(hour: 13, min: 0)
    )

    page.execute_script("localStorage.setItem('languageCode', 'vi')")
    visit mobile_company_attendance_month_path(company)

    expect(page).to have_content("Nửa ngày", wait: 10)
    expect(page).not_to have_content("Half day")
  end
end
