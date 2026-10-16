# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Dynamic sidebar editor", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }
  let!(:dynamic_setting) do
    CompanySetting.create!(
      company: company, name: "Company Quick Links", business_type: :sidebar_groups,
      workflow_status: :active,
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
      "company_settings" => company.company_settings.reset.map { |s| JSON.parse(s.to_json) },
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
    visit company_company_settings_path(company)

    expect(page).to have_content("Company Quick Links", wait: 10)

    click_button "Add Group", match: :first
    fill_in "Group name", match: :first, with: "My Links"

    click_button "Add Sidebar Item", match: :first
    fill_in "Item name", match: :first, with: "Pending Orders"
    fill_in "Item URL", match: :first, with: "/pending?workflow_status=pending"

    click_button "Save Changes", match: :first

    expect(page).to have_content("Company setting updated successfully", wait: 10)
    within("aside", visible: :all) do
      expect(page).to have_selector("details[data-sidebar-group^='custom_']", visible: :all, wait: 10)
      expect(page).to have_link("Pending Orders", href: "/pending?workflow_status=pending", visible: :all, wait: 10)
    end
    expect(dynamic_setting.reload.sidebar_groups.first["name"]).to eq("My Links")
  end
end
