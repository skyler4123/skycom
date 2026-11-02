require "rails_helper"

RSpec.feature "Companies::KpiConfigs Index", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let!(:kpi_config) do
    create(:kpi_config, company: company, name: "Orders sold", metric_key: "orders_count",
      target_value: 10, weight: 1)
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
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "owner sees the configured KPIs" do
    sign_in(owner)
    seed_client_cache(owner)

    visit company_kpi_configs_path(company)

    expect(page).to have_content("KPI Settings", wait: 10)
    expect(page).to have_content("Orders sold")
    expect(page).to have_button("Add KPI")
  end

  scenario "owner creates a revenue KPI" do
    company.update_columns(currency: Company.currencies[:usd], country: Company.countries[:us])

    sign_in(owner)
    seed_client_cache(owner)

    visit company_kpi_configs_path(company)
    click_link_or_button "Add KPI"

    expect(page).to have_field("kpi_config[name]", wait: 10)
    fill_in "kpi_config[name]", with: "Monthly revenue"
    select "Sales revenue", from: "kpi_config[metric_key]"
    fill_in "kpi_config[target_value]", with: "1000"
    fill_in "kpi_config[weight]", with: "3"
    click_button "Save KPI"

    expect(page).to have_content("Monthly revenue", wait: 10)
    created = KpiConfig.find_by!(name: "Monthly revenue")
    expect(created.target_value).to eq(100_000)
    expect(created.weight).to eq(3)
  end

  scenario "owner creates a VND revenue KPI without scaling the target" do
    company.update_columns(currency: Company.currencies[:vnd], country: Company.countries[:vn])

    sign_in(owner)
    seed_client_cache(owner)

    visit company_kpi_configs_path(company)
    click_link_or_button "Add KPI"

    expect(page).to have_field("kpi_config[name]", wait: 10)
    fill_in "kpi_config[name]", with: "Doanh thu"
    select "Sales revenue", from: "kpi_config[metric_key]"
    fill_in "kpi_config[target_value]", with: "1000"
    click_button "Save KPI"

    expect(page).to have_content("Doanh thu", wait: 10)
    expect(KpiConfig.find_by!(name: "Doanh thu").target_value).to eq(1000)
  end

  scenario "owner edits a KPI target" do
    sign_in(owner)
    seed_client_cache(owner)

    visit company_kpi_configs_path(company)
    find("tr[data-kpi-config-id='#{kpi_config.id}']").all("button").first.click

    expect(page).to have_field("kpi_config[target_value]", wait: 10)
    fill_in "kpi_config[target_value]", with: "25"
    click_button "Save KPI"

    expect(page).to have_content("25", wait: 10)
    expect(kpi_config.reload.target_value).to eq(25)
  end

  scenario "owner deletes a KPI" do
    sign_in(owner)
    seed_client_cache(owner)

    visit company_kpi_configs_path(company)
    find("tr[data-kpi-config-id='#{kpi_config.id}']").all("button").last.click
    find(".swal2-confirm", wait: 5).click

    expect(page).not_to have_content("Orders sold", wait: 10)
    expect(KpiConfig.exists?(kpi_config.id)).to be(false)
  end

  scenario "manager can read the list but cannot manage it" do
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

    visit company_kpi_configs_path(company)

    expect(page).to have_content("Orders sold", wait: 10)
    expect(page).not_to have_link("Add KPI")
    expect(page).not_to have_button("Add KPI")
  end

  scenario "employee without the KpiConfig read permission is rejected" do
    employee_user = create(:user, :company_employee)
    create(:employee, company: company, user: employee_user)

    sign_in(employee_user)
    seed_client_cache(employee_user)

    visit company_kpi_configs_path(company)

    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)
    expect(page).not_to have_content("KPI Settings")
  end
end
