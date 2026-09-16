# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Sidebar grouping", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }

  before do
    sign_in(owner)
    seed_client_cache!
  end

  def seed_client_cache!
    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "settings" => company.settings.reset.map { |s| JSON.parse(s.to_json) },
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

  scenario "sidebar renders all groups with their items" do
    visit company_dashboards_path(company)

    within("aside", visible: :all) do
      %w[general catalog sales organization platform attendance inventory authorization system].each do |group|
        expect(page).to have_selector("p", text: /\A#{group}\z/i, visible: :all, wait: 10)
      end
    end

    within('[data-sidebar-group="general"]', visible: :all) do
      expect(page).to have_link("Dashboard", href: /dashboards/, visible: :all, wait: 10)
      expect(page).to have_link("Analytics", href: /analytics/, visible: :all)
      expect(page).to have_no_link("Products", visible: :all)
    end

    within('[data-sidebar-group="inventory"]', visible: :all) do
      expect(page).to have_link("Warehouses", href: /warehouses/, visible: :all, wait: 10)
      expect(page).to have_link("Stocks", href: /stocks/, visible: :all)
      expect(page).to have_no_link("Dashboard", visible: :all)
    end

    within('[data-sidebar-group="authorization"]', visible: :all) do
      expect(page).to have_link("Policies", href: /policies/, visible: :all, wait: 10)
      expect(page).to have_link("Permissions", href: /permissions/, visible: :all)
    end

    within('[data-sidebar-group="system"]', visible: :all) do
      expect(page).to have_link("Usage", href: /usage/, visible: :all, wait: 10)
      expect(page).to have_link("Top Up", href: /top_ups/, visible: :all)
      expect(page).to have_link("Billing", href: /billing/, visible: :all)
      expect(page).to have_link("Settings", visible: :all)
    end
  end

  scenario "hides a whole group when its group visibility is off" do
    company.settings.company_level.find_by(code: "SETTINGS-DEFAULT").update!(
      sidebar_groups: Company::SIDEBAR_GROUP_KEYS.map { |key|
        { "key" => key, "visible" => key != "inventory" }
      }
    )
    seed_client_cache!

    visit company_dashboards_path(company)

    within("aside", visible: :all) do
      expect(page).to have_selector('[data-sidebar-group="general"]', visible: :all, wait: 10)
      expect(page).to have_no_selector('[data-sidebar-group="inventory"]', visible: :all)
    end
  end

  scenario "does not render an empty group header when all its items are hidden" do
    attendance_keys = %w[shift_templates scheduled_shifts attendance_days attendance_policies attendance_logs attendance_months]
    company.settings.company_level.find_by(code: "SETTINGS-DEFAULT").update!(
      sidebar_items: Company::SIDEBAR_ITEM_KEYS.map { |key|
        { "key" => key, "visible" => !key.in?(attendance_keys) }
      }
    )
    seed_client_cache!

    visit company_dashboards_path(company)

    within("aside", visible: :all) do
      expect(page).to have_selector('[data-sidebar-group="general"]', visible: :all, wait: 10)
      expect(page).to have_no_selector('[data-sidebar-group="attendance"]', visible: :all)
    end
  end
end
