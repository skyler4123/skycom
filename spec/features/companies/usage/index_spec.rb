# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::Usage", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }
  let(:today) { Time.current.to_date }

  before do
    sign_in(owner)

    company.company_wallet.add_credits!(amount: 1_500_000)

    # 7 days of deterministic usage: i days ago → total (i + 1) * 100
    7.times do |i|
      date = i.days.ago.to_date
      usage = CompanyDailyUsage.find_or_create_for(company, date)
      usage.set_hour_usage(10, (i + 1) * 100)
    end
    company.record_credit_usage!(50)

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

  scenario "displays the credit balance and stat cards" do
    visit company_usage_path(company)

    expect(page).to have_content(/credit balance/i, wait: 10)
    expect(page).to have_content("1,500,000", wait: 10)
    expect(page).to have_content(/live delta/i, wait: 10)
    expect(page).to have_content("50", wait: 10)
    expect(page).to have_content(/monthly total/i, wait: 10)
  end

  scenario "renders the 7-day usage chart" do
    visit company_usage_path(company)

    chart_container = find('[data-companies--usage--show-target="usageChart"]', wait: 10)
    expect(chart_container).to have_selector("svg", wait: 10)
  end

  scenario "includes the live delta in today's total" do
    visit company_usage_path(company)

    # i=0 → today: 100 credits + 50 live delta = 150
    expect(page).to have_content("150", wait: 10)
  end
end
