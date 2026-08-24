# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Usage logging toggle", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }

  before do
    sign_in(owner)

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
  end

  scenario "usage log table renders an empty layout by default" do
    visit company_usage_path(company)

    expect(page).to have_content("Usage Logs", wait: 10)
    expect(page).to have_content("Enable logging to capture credit movements")
    expect(page).to have_button("Enable Logging")
    expect(page).to have_no_button("Stop Logging")
    expect(page).to have_no_selector("tbody tr")
  end

  scenario "enabling logging records wallet movements and stopping clears the table" do
    seed_random_wallet!(company)

    visit company_usage_path(company)
    expect(page).to have_button("Enable Logging", wait: 10)

    click_button "Enable Logging"

    expect(page).to have_button("Stop Logging", wait: 10)
    expect(page).to have_selector("span", text: /recording · 05:/i)
    expect(page).to have_content("No activity captured yet")

    # Trigger a credit-consuming action while recording (dashboards deducts 2)
    visit company_dashboards_path(company)
    expect(page).to have_selector('[data-chart="products"]', wait: 10)

    10.times do
      break if company.company_wallet.reload.company_usage_logs.exists?
      sleep 0.2
    end
    expect(company.company_wallet.reload.company_usage_logs.exists?).to be true

    visit company_usage_path(company)
    expect(page).to have_button("Stop Logging", wait: 10)

    find('button[aria-label="Refresh"]').click

    expect(page).to have_selector("td", text: /access dashboard/i, wait: 10)
    expect(page).to have_selector("td", text: /\A-2\z/)

    click_button "Stop Logging"

    expect(page).to have_button("Enable Logging", wait: 10)
    expect(page).to have_content("Enable logging to capture credit movements")
    expect(page).to have_no_selector("tbody tr")
  end
end
