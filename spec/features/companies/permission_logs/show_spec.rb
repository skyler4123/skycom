require "rails_helper"

RSpec.feature "Companies::PermissionLogs Show", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  let!(:log) do
    create(:permission_log, company: company, action: :conditions_changed,
      role_name: "Seller", policy_name: "Can read Product",
      resource_name: "Product", policy_action: "read", employee_name: "Jane Doe",
      metadata: {
        "tag_conditions_before" => {},
        "tag_conditions_after" => { "brand" => "Apple" }
      })
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

  scenario "displays the log snapshot with actor, action and conditions diff" do
    visit company_permission_log_path(company, log)

    expect(page).to have_content("Permission Log", wait: 10)
    expect(page).to have_content("Conditions changed")
    expect(page).to have_content("Jane Doe")
    expect(page).to have_content("Seller")
    expect(page).to have_content("Tag Conditions")
  end

  scenario "has back link to index page" do
    visit company_permission_log_path(company, log)

    back_link = find("a[href*='/permission_logs']", match: :first, wait: 10)
    expect(back_link).to be_present
  end
end
