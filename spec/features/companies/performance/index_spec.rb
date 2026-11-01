require "rails_helper"

RSpec.feature "Companies::Performance Index", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  let!(:employee_user) { create(:user, :company_employee) }
  let!(:employee) { create(:employee, company: company, user: employee_user) }
  let!(:kpi_config) do
    create(:kpi_config, company: company, name: "Orders sold", metric_key: "orders_count",
      target_value: 10, period_type: :month)
  end

  let(:in_range) { Time.zone.parse("2026-03-15 10:00:00") }

  before do
    12.times { create_paid_order(company: company, salesperson: employee, created_at: in_range) }
    create_paid_order(company: company, salesperson: nil, created_at: in_range)
  end

  def seed_client_cache(user)
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
      user: JSON.parse(user.to_json),
      companies: [ company_data ],
      enums: {},
      employees: [ JSON.parse(employee.to_json) ]
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "owner sees the leaderboard and unattributed orders for a custom period" do
    sign_in(owner)
    seed_client_cache(owner)

    visit "#{company_performance_index_path(company)}?period=custom&from=2026-03-01&to=2026-03-31"

    expect(page).to have_selector("[data-performance-row]", wait: 10)
    expect(page).to have_selector(
      "[data-performance-employee='#{employee.id}'] [data-performance-composite]",
      text: "120.0%",
      wait: 10
    )
    expect(page).to have_selector("[data-unattributed-banner]", wait: 10)
    expect(page).to have_content("Unattributed orders")
  end

  scenario "manager can see performance but not KPI settings" do
    manager_role = create(:role, company: company, name: "Manager")
    manager_user = create(:user, :company_employee)
    manager_employee = create(:employee, company: company, user: manager_user)
    create(:employee_role_appointment, company: company, employee: manager_employee, role: manager_role)
    read_policy = Seed::PolicyService.create(
      company: company, name: "Can read KpiConfig", resource: "KpiConfig",
      action: "read", business_type: :operational, lifecycle_status: :active
    )
    create(:policy_role_appointment, company: company, role: manager_role, policy: read_policy,
      workflow_status: :active)

    sign_in(manager_user)
    seed_client_cache(manager_user)

    visit company_performance_index_path(company)

    expect(page).to have_selector("[data-performance-row]", wait: 10)
    expect(page).not_to have_link("KPI Settings")
  end

  scenario "employee without the KpiConfig read permission is rejected" do
    sign_in(employee_user)
    seed_client_cache(employee_user)

    visit company_performance_index_path(company)

    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)
    expect(page).not_to have_selector("[data-performance-row]")
  end
end
