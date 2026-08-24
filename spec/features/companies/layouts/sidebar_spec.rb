# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Sidebar grouping", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }

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

  scenario "sidebar separates company items from system items" do
    visit company_dashboards_path(company)

    within("aside", visible: :all) do
      expect(page).to have_selector("p", text: /\Acompany\z/i, visible: :all, wait: 10)
      expect(page).to have_selector("p", text: /\Asystem\z/i, visible: :all)
    end

    within('[data-sidebar-group="company"]', visible: :all) do
      expect(page).to have_link("Dashboard", href: /dashboards/, visible: :all, wait: 10)
      expect(page).to have_link("Facilities", href: /facilities/, visible: :all)

      expect(page).to have_no_link("Billing", visible: :all)
      expect(page).to have_no_link("Usage", visible: :all)
      expect(page).to have_no_link("Top Up", visible: :all)
      expect(page).to have_no_link("Settings", visible: :all)
    end

    within('[data-sidebar-group="system"]', visible: :all) do
      expect(page).to have_link("Usage", href: /usage/, visible: :all, wait: 10)
      expect(page).to have_link("Top Up", href: /top_ups/, visible: :all)
      expect(page).to have_link("Billing", href: /billing/, visible: :all)

      settings_link = find_link("Settings", visible: :all)
      expect(settings_link["aria-disabled"]).to eq("true")
      expect(settings_link[:href]).to end_with("#")
    end
  end
end
