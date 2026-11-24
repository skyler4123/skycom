# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Dynamic sidebar", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }
  let!(:dynamic_setting) do
    CompanySetting.create!(
      company: company, name: "Company Quick Links", business_type: :sidebar_groups,
      workflow_status: :active,
      sidebar_groups: [
        { "key" => "my-links", "name" => "My Links",
          "items" => [ { "key" => "pending-orders", "name" => "Pending Orders", "url" => "/pending?workflow_status=pending" } ] }
      ]
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

  scenario "renders Quick Links groups between Operations and My Profile" do
    visit company_dashboards_path(company)

    within("aside", visible: :all) do
      expect(page).to have_selector("details[data-sidebar-group='custom_my-links']", visible: :all, wait: 10)

      general_pos = page.body.index('data-sidebar-group="general"')
      operations_pos = page.body.index('data-sidebar-group="operations"')
      custom_pos = page.body.index('data-sidebar-group="custom_my-links"')
      my_profile_pos = page.body.index('data-sidebar-group="my_profile"')

      expect([ general_pos, operations_pos, custom_pos, my_profile_pos ]).to all(be_a(Integer))
      expect(general_pos).to be < operations_pos
      expect(operations_pos).to be < custom_pos
      expect(custom_pos).to be < my_profile_pos
    end
  end

  scenario "Quick Links items keep pasted urls with params and can be starred" do
    visit company_dashboards_path(company)

    find("details[data-sidebar-group='custom_my-links'] summary", visible: :all).click
    within("details[data-sidebar-group='custom_my-links']", visible: :all) do
      expect(page).to have_link("Pending Orders", href: "/pending?workflow_status=pending", visible: :all, wait: 10)
      expect(page).to have_selector("button[data-sidebar-star='custom_item_pending-orders']", visible: :all)
    end

    find("button[data-sidebar-star='custom_item_pending-orders']", visible: :all).click

    within("[data-sidebar-favourites]", visible: :all) do
      expect(page).to have_link("Pending Orders", href: "/pending?workflow_status=pending", visible: :all, wait: 10)
    end

    page.refresh

    within("[data-sidebar-favourites]", visible: :all) do
      expect(page).to have_link("Pending Orders", href: "/pending?workflow_status=pending", visible: :all, wait: 10)
    end
  end
end
