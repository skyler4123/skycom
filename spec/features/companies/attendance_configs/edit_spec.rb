require "rails_helper"

RSpec.feature "Companies::AttendanceConfigs Edit", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company) }

  let!(:attendance_config) { create(:attendance_config, company: company, branch: branch) }

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

  scenario "pre-fills form with current values" do
    visit edit_company_attendance_config_path(company, attendance_config)
    expect(page).to have_selector("input[name='attendance_config[branch_id]']", wait: 10)
    branch_field = find("input[name='attendance_config[branch_id]']")
    expect(branch_field).to be_present
  end

  scenario "updates attendance policy and redirects to show page" do
    visit edit_company_attendance_config_path(company, attendance_config)
    expect(page).to have_selector("input[name='attendance_config[latitude]']", wait: 10)

    fill_in "attendance_config[branch_id]", with: branch.id
    fill_in "attendance_config[latitude]", with: "11.0"
    fill_in "attendance_config[longitude]", with: attendance_config.longitude
    click_button "Save Changes"

    expect(page).to have_current_path(company_attendance_config_path(company, attendance_config), wait: 10)
    expect(page).to have_content("11.0", wait: 10)
    attendance_config.reload
    expect(attendance_config.latitude).to eq(11.0)
  end

  scenario "handles validation error" do
    visit edit_company_attendance_config_path(company, attendance_config)
    expect(page).to have_selector("input[name='attendance_config[branch_id]']", wait: 10)

    fill_in "attendance_config[branch_id]", with: ""
    fill_in "attendance_config[latitude]", with: ""
    fill_in "attendance_config[longitude]", with: ""
    page.execute_script("document.querySelector('select[name=\"attendance_config[resolution_strategy]\"]').selectedIndex = -1")
    click_button "Save Changes"
    expect(page).to have_current_path(edit_company_attendance_config_path(company, attendance_config), wait: 10)
  end
end
