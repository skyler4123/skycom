# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Sidebar search", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }

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

  scenario "typing a lowercase prefix lists matching sidebar items as links" do
    visit company_dashboards_path(company)

    within("aside", visible: :all) do
      expect(page).to have_selector("input[data-sidebar-search-input]", visible: :all, wait: 10)
      fill_in "sidebar_search", with: "t"
      expect(page).to have_link("Tickets", href: /tickets/, wait: 10)
    end
  end

  scenario "search is case-insensitive (uppercase input still matches)" do
    visit company_dashboards_path(company)

    within("aside", visible: :all) do
      fill_in "sidebar_search", with: "T"
      expect(page).to have_link("Tickets", href: /tickets/, wait: 10)
    end
  end

  scenario "clicking a search result navigates to the item page" do
    visit company_dashboards_path(company)

    within("aside", visible: :all) do
      fill_in "sidebar_search", with: "t"
      expect(page).to have_link("Tickets", href: /tickets/, wait: 10)
      click_link "Tickets"
    end

    expect(page).to have_current_path(/tickets/, wait: 10)
  end

  scenario "Vietnamese locale: typing t lists Vietnamese-labelled items" do
    page.execute_script("localStorage.setItem('languageCode', 'vi')")
    visit company_dashboards_path(company)

    within("aside", visible: :all) do
      fill_in "sidebar_search", with: "t"
      expect(page).to have_link("Trang", wait: 10)
      expect(page).to have_link("Tài liệu", wait: 10)
    end
  end

  scenario "clearing the input clears the results" do
    visit company_dashboards_path(company)

    within("aside", visible: :all) do
      fill_in "sidebar_search", with: "t"
      expect(page).to have_link("Tickets", wait: 10)

      fill_in "sidebar_search", with: ""
      expect(page).to have_no_link("Tickets", wait: 10)
    end
  end
end