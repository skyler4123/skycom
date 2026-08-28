require "rails_helper"

RSpec.feature "Companies::Settings Management", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  before do
    sign_in(owner)

    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "settings" => company.settings.reset.map { |s| JSON.parse(s.to_json) },
      "branches" => [],
      "departments" => [],
      "roles" => [],
      "categories" => [],
      "property_mappings" => [],
      "table_configs" => []
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

  scenario "shows all sidebar items by default" do
    visit company_settings_path(company)

    within("aside nav") do
      expect(page).to have_content("Dashboard", wait: 10)
      expect(page).to have_content("Products")
      expect(page).to have_content("Settings")
    end
  end

  scenario "toggles a sidebar item off and hides it from the sidebar" do
    visit company_settings_path(company)

    expect(page).to have_content("Sidebar Items", wait: 10)

    products_row = page.find("label", text: "Products")
    checkbox = products_row.find('input[type="checkbox"]')
    expect(checkbox).to be_checked
    checkbox.click

    click_button "Save Changes"
    expect(page).to have_current_path(company_settings_path(company), wait: 10)

    within("aside nav") do
      expect(page).to have_content("Dashboard", wait: 10)
      expect(page).not_to have_content("Products")
    end
  end
end
