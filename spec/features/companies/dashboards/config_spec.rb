# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Dashboard configuration", type: :feature, js: true do
  def seed_client_cache(company:, user:, employee: nil)
    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
      "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
      "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
      "branches" => company.branches.reset.map { |b| JSON.parse(b.to_json) },
      "departments" => [],
      "roles" => []
    )

    payload = {
      user: JSON.parse(user.to_json),
      companies: [ company_data ],
      enums: {},
      employees: employee ? [ JSON.parse(employee.to_json) ] : []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  let(:company) do
    create(:company, :without_signup_promo, business_type: :retail, name: "Config Spec Co")
  end
  let(:owner) { company.user }

  before do
    company.company_wallet.add_credits!(amount: 100)
    sign_in(owner)
    seed_client_cache(company: company, user: owner)
  end

  scenario "shows all blocks by default and opens the config page from the dashboard" do
    visit company_dashboards_path(company)

    expect(page).to have_content("Company health", wait: 10)
    expect(page).to have_selector('[data-dashboard-block="company_meta"]', wait: 10)
    expect(page).to have_selector('[data-dashboard-block="kpis"]', wait: 10)

    click_link "Config"

    expect(page).to have_current_path(company_dashboard_path(company), wait: 10)
    expect(page).to have_content("Dashboard configuration", wait: 10)
    expect(page).to have_checked_field("Company details")
    expect(page).to have_checked_field("Key metrics")
  end

  scenario "lists Dashboard Config under the Settings sidebar group" do
    visit company_dashboards_path(company)

    expect(page).to have_selector(
      "details[data-sidebar-group='settings'] a[href='#{company_dashboard_path(company)}']",
      visible: :all,
      wait: 10
    )
  end

  scenario "hides a disabled block on the dashboard after saving" do
    visit company_dashboard_path(company)

    expect(page).to have_content("Dashboard configuration", wait: 10)
    uncheck "Company details"
    click_button "Save changes"

    expect(page).to have_content("Dashboard updated successfully", wait: 10)

    visit company_dashboards_path(company)

    expect(page).to have_content("Company health", wait: 10)
    expect(page).not_to have_selector('[data-dashboard-block="company_meta"]')
    expect(page).to have_selector('[data-dashboard-block="kpis"]', wait: 10)
  end
end
