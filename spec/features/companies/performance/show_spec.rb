require "rails_helper"

RSpec.feature "Companies::Performance Show", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let!(:employee) { create(:employee, company: company) }
  let!(:kpi_config) do
    create(:kpi_config, company: company, name: "Orders sold", metric_key: "orders_count",
      target_value: 10, weight: 1)
  end
  let(:in_range) { Time.zone.parse("2026-03-15 10:00:00") }

  def seed_client_cache
    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => [],
      "table_configs" => [],
      "categories" => [],
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

  scenario "owner sees one employee's KPI breakdown" do
    12.times { create_paid_order(company: company, salesperson: employee, created_at: in_range) }

    sign_in(owner)
    seed_client_cache

    visit "#{company_performance_path(company, employee)}?period=custom&from=2026-03-01&to=2026-03-31"

    expect(page).to have_content(employee.name, wait: 10)
    expect(page).to have_selector("[data-scorecard-row]", wait: 10)
    expect(page).to have_selector("[data-scorecard-composite]", text: "120.0%", wait: 10)
    expect(page).to have_content("Orders sold")
  end
end
