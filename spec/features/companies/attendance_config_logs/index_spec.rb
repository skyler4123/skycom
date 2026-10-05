require "rails_helper"

RSpec.feature "Companies::AttendanceConfigLogs Management", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company, name: "Main Branch") }

  let!(:attendance_config) { create(:attendance_config, company: company, branch: branch) }

  let!(:created_log) do
    create(:attendance_config_log, company: company, attendance_config: attendance_config,
      branch: branch, action: :created, branch_name: branch.name,
      allowed_radius_meters: 100, employee_name: "Jane Doe")
  end

  let!(:updated_log) do
    create(:attendance_config_log, company: company, attendance_config: attendance_config,
      branch: branch, action: :updated, branch_name: branch.name,
      allowed_radius_meters: 200, employee_name: "John Smith")
  end

  before do
    sign_in(owner)

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

  scenario "index page loads and displays log rows with actor and action" do
    visit company_attendance_config_logs_path(company)

    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_content("Attendance Config Logs")
    expect(page).to have_selector("th", text: "Branch")
    expect(page).to have_selector("th", text: "Changed By")
    expect(page).to have_content("Main Branch")
    expect(page).to have_content("Created")
    expect(page).to have_content("Updated")
    expect(page).to have_content("Jane Doe")
    expect(page).to have_content("John Smith")
  end

  scenario "index has filter controls for config, branch, action and dates" do
    visit company_attendance_config_logs_path(company)

    expect(page).to have_selector("select[name='attendance_config_id']", wait: 10)
    expect(page).to have_selector("select[name='branch_id']")
    expect(page).to have_selector("select[name='log_action']")
    expect(page).to have_selector("input[name='from']")
    expect(page).to have_selector("input[name='to']")
  end

  scenario "filtering by action narrows the rows" do
    visit company_attendance_config_logs_path(company)
    expect(page).to have_content("John Smith", wait: 10)

    select "Created", from: "log_action"
    click_button "Search"

    expect(page).to have_content("Jane Doe", wait: 10)
    expect(page).to have_no_content("John Smith")
  end

  scenario "eye icon links to the log show page" do
    visit company_attendance_config_logs_path(company)
    expect(page).to have_selector("table", wait: 10)

    eye_link = find("a[href*='/attendance_config_logs/#{created_log.id}']", match: :first)
    expect(eye_link).to be_present
  end
end
