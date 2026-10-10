# frozen_string_literal: true

require "rails_helper"

# Dark mode is global: Tailwind v4 class strategy via
# `@custom-variant dark` (app/assets/tailwind/application.css) keyed off
# `<html class="dark">`, toggled by DarkmodeController and persisted in
# `localStorage["darkmode"]`. Regression coverage for the reload bug where
# `<html>` lost `dark` on full page load (controller early-returned on the
# first value assignment, and no head script pre-applied the class).
RSpec.feature "Darkmode across sidebar pages", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }

  before do
    sign_in(owner)
    seed_client_cache!
  end

  def seed_client_cache!
    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
      "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
      "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
      "branches" => [],
      "departments" => [],
      "roles" => []
    )

    payload = {
      user: JSON.parse(owner.to_json),
      companies: [ company_data ],
      enums: {},
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
    page.execute_script("localStorage.setItem('open-cache-sidebar', 'sidebar')")
  end

  def html_dark?
    page.evaluate_script("document.documentElement.classList.contains('dark')")
  end

  scenario "toggle persists to localStorage and html class" do
    visit company_brands_path(company)
    expect(page).to have_selector("header", wait: 10)

    # Start light
    page.execute_script("localStorage.setItem('darkmode', 'false')")
    page.execute_script("document.documentElement.classList.remove('dark')")
    expect(html_dark?).to be(false)

    find("[data-darkmode-target='trigger']", match: :first, visible: :all).click
    expect(page.evaluate_script("localStorage.getItem('darkmode')")).to eq("true")
    expect(html_dark?).to be(true)

    find("[data-darkmode-target='trigger']", match: :first, visible: :all).click
    expect(page.evaluate_script("localStorage.getItem('darkmode')")).to eq("false")
    expect(html_dark?).to be(false)
  end

  scenario "dark mode survives full reload without clicking (reported bug)" do
    page.execute_script("localStorage.setItem('darkmode', 'true')")
    visit company_brands_path(company)

    expect(page).to have_selector("header", wait: 10)
    # Controller must re-apply stored theme on boot; head pre-apply script
    # should already have it before Stimulus connects.
    expect(html_dark?).to be(true)
  end

  scenario "dark mode persists across Turbo sidebar navigation with working toggle" do
    visit company_brands_path(company)
    expect(page).to have_selector("header", wait: 10)

    page.execute_script("localStorage.setItem('darkmode', 'false')")
    page.execute_script("document.documentElement.classList.remove('dark')")
    find("[data-darkmode-target='trigger']", match: :first, visible: :all).click
    expect(html_dark?).to be(true)

    find("details[data-sidebar-group='general'] summary", visible: :all).click
    click_link("Dashboard", visible: :all)
    expect(page).to have_selector("header", wait: 10)
    expect(html_dark?).to be(true)
    # Toggle icons must survive the navigation (re-rendered header).
    expect(page).to have_selector("[data-darkmode-target='trigger'] svg", visible: :all, wait: 10)
  end

  scenario "dark mode holds across all sidebar index pages" do
    page.execute_script("localStorage.setItem('darkmode', 'true')")

    paths = [
      company_dashboards_path(company),
      company_notifications_path(company),
      company_analytics_path(company),
      company_products_path(company),
      company_brands_path(company),
      company_services_path(company),
      company_orders_path(company),
      company_customers_path(company),
      company_invoices_path(company),
      company_purchases_path(company),
      company_discount_groups_path(company),
      company_branches_path(company),
      company_departments_path(company),
      company_employees_path(company),
      company_facilities_path(company),
      company_categories_path(company),
      company_property_mappings_path(company),
      company_table_configs_path(company),
      company_workflows_path(company),
      company_pages_path(company),
      company_documents_path(company),
      company_calendar_path(company),
      company_events_path(company),
      company_event_configs_path(company),
      company_shift_templates_path(company),
      company_scheduled_shifts_path(company),
      company_attendance_days_path(company),
      company_attendance_configs_path(company),
      company_attendance_logs_path(company),
      company_attendance_months_path(company),
      company_warehouses_path(company),
      company_stocks_path(company),
      company_stock_transfers_path(company),
      company_stock_imports_path(company),
      company_stock_exports_path(company),
      company_stock_adjustments_path(company),
      company_suppliers_path(company),
      company_policies_path(company),
      company_permissions_path(company),
      company_settings_path(company)
    ]

    paths.each do |path|
      visit path
      # Header renders once layout + client cache resolve; theme must already hold.
      expect(page).to have_selector("header", wait: 10)
      expect(html_dark?).to(be(true), "expected dark mode on #{path}")
      expect(page).to have_selector("[data-darkmode-target='trigger'] svg", visible: :all, wait: 10)
    end
  end
end
