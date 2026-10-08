require "rails_helper"

RSpec.feature "Companies::PermissionLogs Management", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  let!(:granted_log) do
    create(:permission_log, company: company, action: :granted,
      role_name: "Seller", policy_name: "Can read Order",
      resource_name: "Order", policy_action: "read", employee_name: "Jane Doe")
  end

  let!(:revoked_log) do
    create(:permission_log, company: company, action: :revoked,
      role_name: "Cashier", policy_name: "Can delete Order",
      resource_name: "Order", policy_action: "delete", employee_name: "John Smith")
  end

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

  scenario "index page loads and displays log rows with actor and action" do
    visit company_permission_logs_path(company)

    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_content("Permission Logs")
    expect(page).to have_selector("th", text: "Role")
    expect(page).to have_selector("th", text: "Changed By")
    expect(page).to have_content("Seller")
    expect(page).to have_content("Granted")
    expect(page).to have_content("Revoked")
    expect(page).to have_content("Jane Doe")
    expect(page).to have_content("John Smith")
  end

  scenario "index has filter controls for role, resource, action and dates" do
    visit company_permission_logs_path(company)

    expect(page).to have_selector("select[name='role_id']", wait: 10)
    expect(page).to have_selector("select[name='resource_name']")
    expect(page).to have_selector("select[name='log_action']")
    expect(page).to have_selector("input[name='from']")
    expect(page).to have_selector("input[name='to']")
  end

  scenario "filtering by action narrows the rows" do
    visit company_permission_logs_path(company)
    expect(page).to have_content("John Smith", wait: 10)

    select "Granted", from: "log_action"
    click_button "Search"

    expect(page).to have_content("Jane Doe", wait: 10)
    expect(page).to have_no_content("John Smith")
  end

  scenario "eye icon links to the log show page" do
    visit company_permission_logs_path(company)
    expect(page).to have_selector("table", wait: 10)

    eye_link = find("a[href*='/permission_logs/#{granted_log.id}']", match: :first)
    expect(eye_link).to be_present
  end
end
