# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Analytics configuration", type: :feature, js: true do
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
    create(:company, :without_signup_promo, business_type: :retail, name: "Analytics Config Spec Co")
  end
  let(:owner) { company.user }

  before do
    company.company_wallet.add_credits!(amount: 100)
    sign_in(owner)
    seed_client_cache(company: company, user: owner)
  end

  scenario "shows all blocks by default and opens the config page from analytics" do
    visit company_analytics_path(company)

    expect(page).to have_content("Executive analysis", wait: 10)
    expect(page).to have_selector('[data-analytics-block="pillars"]', wait: 10)
    expect(page).to have_selector('[data-analytics-block="revenue_mix"]', wait: 10)

    click_link "Config"

    expect(page).to have_current_path(company_analytic_path(company), wait: 10)
    expect(page).to have_content("Analytics configuration", wait: 10)
    expect(page).to have_checked_field("Key pillars")
    expect(page).to have_checked_field("Revenue mix")
  end

  scenario "lists Analytics Config under the Settings sidebar group" do
    visit company_analytics_path(company)

    expect(page).to have_selector(
      "details[data-sidebar-group='settings'] a[href='#{company_analytic_path(company)}']",
      visible: :all,
      wait: 10
    )
  end

  scenario "hides a disabled block on analytics after saving" do
    visit company_analytic_path(company)

    expect(page).to have_content("Analytics configuration", wait: 10)
    uncheck "Key pillars"
    click_button "Save changes"

    expect(page).to have_content("Analytics updated successfully", wait: 10)

    visit company_analytics_path(company)

    expect(page).to have_content("Executive analysis", wait: 10)
    expect(page).not_to have_selector('[data-analytics-block="pillars"]')
    expect(page).to have_selector('[data-analytics-block="revenue_mix"]', wait: 10)
  end

  scenario "shows the empty state when every block is disabled" do
    company.analytic.update!(blocks: [])

    visit company_analytics_path(company)

    expect(page).to have_content("No analytics blocks are enabled. Use Config to choose what to show.", wait: 10)
  end
end
