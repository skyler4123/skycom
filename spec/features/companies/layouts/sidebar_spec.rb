# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Sidebar favourites", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }
  let(:other_company) { create(:company, user: owner) }

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

  scenario "renders groups as collapsed details with the favourites hint" do
    visit company_dashboards_path(company)

    within("aside", visible: :all) do
      expect(page).to have_selector('[data-sidebar-favourites]', visible: :all, wait: 10)
      expect(page).to have_selector("p", text: "Click the star on any item to pin it here", visible: :all, wait: 10)

      %w[general catalog sales organization platform attendance inventory authorization system].each do |group|
        expect(page).to have_selector("details[data-sidebar-group='#{group}']", visible: :all, wait: 10)
        expect(page).to have_no_selector("details[data-sidebar-group='#{group}'][open]", visible: :all)
      end
    end
  end

  scenario "opening a group reveals its items and persists across reload" do
    visit company_dashboards_path(company)

    find("details[data-sidebar-group='catalog'] summary", visible: :all).click
    within("details[data-sidebar-group='catalog']", visible: :all) do
      expect(page).to have_link("Products", href: /products/, visible: :all, wait: 10)
      expect(page).to have_link("Brands", href: /brands/, visible: :all)
    end

    page.refresh

    expect(page).to have_selector("details[data-sidebar-group='catalog'][open]", visible: :all, wait: 10)
    within("details[data-sidebar-group='catalog']", visible: :all) do
      expect(page).to have_link("Products", href: /products/, visible: :all, wait: 10)
    end
  end

  scenario "starring an item adds it to favourites and persists across reload" do
    visit company_dashboards_path(company)

    find("details[data-sidebar-group='catalog'] summary", visible: :all).click
    find("button[data-sidebar-star='products']", visible: :all).click

    within("[data-sidebar-favourites]", visible: :all) do
      expect(page).to have_link("Products", href: /products/, visible: :all, wait: 10)
    end
    expect(page).to have_selector("button[data-sidebar-star='products'][data-sidebar-starred='true']", visible: :all, wait: 10)

    page.refresh

    find("details[data-sidebar-group='catalog'] summary", visible: :all).click
    within("[data-sidebar-favourites]", visible: :all) do
      expect(page).to have_link("Products", href: /products/, visible: :all, wait: 10)
    end
  end

  scenario "un-starring from the favourites section removes the item and restores the hint" do
    visit company_dashboards_path(company)

    find("details[data-sidebar-group='catalog'] summary", visible: :all).click
    find("button[data-sidebar-star='products']", visible: :all).click
    expect(page).to have_selector("[data-sidebar-favourites] a[href*='products']", visible: :all, wait: 10)

    within("[data-sidebar-favourites]", visible: :all) do
      find("button[data-sidebar-star='products']", visible: :all).click
    end

    within("[data-sidebar-favourites]", visible: :all) do
      expect(page).to have_no_link("Products", visible: :all, wait: 10)
      expect(page).to have_selector("p", text: "Click the star on any item to pin it here", visible: :all, wait: 10)
    end
  end

  scenario "favourites are scoped per company" do
    # Re-seed the cache with both companies
    page.execute_script("localStorage.clear()")
    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => [], "table_configs" => [], "categories" => [],
      "branches" => [], "departments" => [], "roles" => []
    )
    other_data = JSON.parse(other_company.to_json).merge(
      "property_mappings" => [], "table_configs" => [], "categories" => [],
      "branches" => [], "departments" => [], "roles" => []
    )
    payload = { user: JSON.parse(owner.to_json), companies: [ company_data, other_data ], enums: {}, employees: [] }
    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
    page.execute_script("localStorage.setItem('open-cache-sidebar', 'sidebar')")

    visit company_dashboards_path(company)
    find("details[data-sidebar-group='catalog'] summary", visible: :all).click
    find("button[data-sidebar-star='products']", visible: :all).click
    expect(page).to have_selector("[data-sidebar-favourites] a[href*='products']", visible: :all, wait: 10)

    visit company_dashboards_path(other_company)

    within("[data-sidebar-favourites]", visible: :all) do
      expect(page).to have_no_link("Products", visible: :all, wait: 10)
      expect(page).to have_selector("p", text: "Click the star on any item to pin it here", visible: :all, wait: 10)
    end
  end

  scenario "system and coming-soon items have no star" do
    visit company_dashboards_path(company)

    within("aside", visible: :all) do
      expect(page).to have_no_selector("button[data-sidebar-star='usage']", visible: :all, wait: 10)
      expect(page).to have_no_selector("button[data-sidebar-star='billing']", visible: :all)
      expect(page).to have_no_selector("button[data-sidebar-star='settings']", visible: :all)
      expect(page).to have_no_selector("button[data-sidebar-star='help_center']", visible: :all)
      expect(page).to have_selector("details[data-sidebar-group='chat_help_desk']", visible: :all, wait: 10)
      expect(page).to have_no_selector("details[data-sidebar-group='chat_help_desk'] button[data-sidebar-star]", visible: :all)
    end
  end

  scenario "the current page link is highlighted after re-render" do
    visit company_products_path(company)

    find("details[data-sidebar-group='catalog'] summary", visible: :all).click
    find("button[data-sidebar-star='products']", visible: :all).click

    within("details[data-sidebar-group='catalog']", visible: :all) do
      expect(page).to have_selector("a[href*='products'][open]", visible: :all, wait: 10)
    end
  end
end
