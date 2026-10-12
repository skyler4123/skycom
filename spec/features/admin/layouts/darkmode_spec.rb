# frozen_string_literal: true

require "rails_helper"

# Admin dark mode reuses the global DarkmodeController
# (localStorage["darkmode"] + <html class="dark">), same as company pages.
RSpec.feature "Admin darkmode", type: :feature, js: true do
  let(:admin) { create(:user, :admin) }

  def html_dark?
    page.evaluate_script("document.documentElement.classList.contains('dark')")
  end

  scenario "admin header has darkmode toggle top-right that persists" do
    sign_in(admin)
    visit admin_companies_path

    expect(page).to have_selector("header", wait: 10)
    expect(page).to have_selector("header [data-darkmode-target='trigger']", wait: 10)

    # Start light
    page.execute_script("localStorage.setItem('darkmode', 'false')")
    page.execute_script("document.documentElement.classList.remove('dark')")
    expect(html_dark?).to be(false)

    find("header [data-darkmode-target='trigger']", match: :first, visible: :all).click
    expect(page.evaluate_script("localStorage.getItem('darkmode')")).to eq("true")
    expect(html_dark?).to be(true)

    find("header [data-darkmode-target='trigger']", match: :first, visible: :all).click
    expect(page.evaluate_script("localStorage.getItem('darkmode')")).to eq("false")
    expect(html_dark?).to be(false)
  end

  scenario "dark mode survives full reload on admin pages" do
    sign_in(admin)
    page.execute_script("localStorage.setItem('darkmode', 'true')")
    visit admin_companies_path

    expect(page).to have_selector("header", wait: 10)
    expect(html_dark?).to be(true)
    expect(page).to have_selector("header [data-darkmode-target='trigger'] svg", visible: :all, wait: 10)
  end
end
