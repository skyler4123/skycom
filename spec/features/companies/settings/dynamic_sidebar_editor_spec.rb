# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Dynamic sidebar editor", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }
  let!(:dynamic_setting) do
    Setting.create!(
      company: company, appoint_to: company, code: DYNAMIC_SIDEBAR_CODE,
      lifecycle_status: :active, workflow_status: :confirmed, business_type: :company,
      sidebar_groups: []
    )
  end

  before do
    sign_in(owner)
    seed_client_cache!
    page.execute_script("localStorage.setItem('open-cache-sidebar', 'sidebar')")
  end

  def seed_client_cache!
    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
      "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
      "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
      "settings" => company.settings.reset.map { |s| JSON.parse(s.to_json) },
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

  scenario "owner creates a custom group with an item and it appears in the sidebar" do
    visit company_settings_path(company)

    expect(page).to have_content("Company Quick Links", wait: 10)
    expect(page).to have_content("My Quick Links", wait: 10)

    click_button "Add Group", match: :first
    fill_in "Group name", match: :first, with: "My Links"

    click_button "Add Sidebar Item", match: :first
    fill_in "Item name", match: :first, with: "Pending Orders"
    fill_in "Item URL", match: :first, with: "/pending?workflow_status=pending"

    click_button "Save Changes", match: :first

    expect(page).to have_content("Dynamic sidebar updated successfully", wait: 10)
    within("aside", visible: :all) do
      expect(page).to have_selector("details[data-sidebar-group^='custom_']", visible: :all, wait: 10)
      expect(page).to have_link("Pending Orders", href: "/pending?workflow_status=pending", visible: :all, wait: 10)
    end
    expect(dynamic_setting.reload.sidebar_groups.first["name"]).to eq("My Links")
  end

  scenario "employee creates a personal link visible only to themselves" do
    visit company_settings_path(company)

    expect(page).to have_content("My Quick Links", wait: 10)

    # Each step re-queries the form: Add Group re-renders contentHTML and would
    # stale any held Capybara scope element.
    within(all("form").last) { click_button "Add Group" }
    within(all("form").last) { fill_in "Group name", with: "Mine" }
    within(all("form").last) { click_button "Add Sidebar Item" }
    within(all("form").last) { fill_in "Item name", with: "My Stocks" }
    within(all("form").last) { fill_in "Item URL", with: "/my-stocks" }
    within(all("form").last) { click_button "Save Changes" }

    expect(page).to have_content("Personal sidebar updated successfully", wait: 10)
    within("aside", visible: :all) do
      expect(page).to have_selector("details[data-sidebar-group^='personal_']", visible: :all, wait: 10)
      expect(page).to have_link("My Stocks", href: "/my-stocks", visible: :all, wait: 10)
    end
  end
end
