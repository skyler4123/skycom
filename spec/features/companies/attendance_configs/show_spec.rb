require "rails_helper"

RSpec.feature "Companies::AttendanceConfigs Show", type: :feature, js: true do
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

  scenario "displays attendance policy details" do
    visit company_attendance_config_path(company, attendance_config)
    expect(page).to have_content(branch.name, wait: 10)
    expect(page).to have_content(attendance_config.latitude.to_s, wait: 10)
    expect(page).to have_content(attendance_config.longitude.to_s)
  end

  scenario "has edit button linking to edit page" do
    visit company_attendance_config_path(company, attendance_config)
    edit_link = find("a[href*='/attendance_configs/#{attendance_config.id}/edit']", match: :first)
    expect(edit_link).to be_present
  end

  scenario "has back link to index page" do
    visit company_attendance_config_path(company, attendance_config)
    back_link = find("a[href*='/attendance_configs']", match: :first)
    expect(back_link).to be_present
  end
end
