# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::Products dynamic search/filter", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "products") }

  let!(:table_config) do
    category.default_property_mapping.table_configs.destroy_all
    TableConfig.create!(company: company, category: category,
      property_mapping: category.default_property_mapping, resource_name: "products",
      metadata: { "columns" => [
        { "key" => "name", "name" => "Name", "visible" => true, "search" => true },
        { "key" => "property_string_1", "name" => "Color", "visible" => true, "search" => true },
        { "key" => "property_integer_1", "name" => "Qty", "visible" => true,
          "filter" => { "type" => "range", "buckets" => [ [ nil, 100 ], [ 100, nil ] ] } },
        { "key" => "property_boolean_1", "name" => "Active", "visible" => true,
          "filter" => { "type" => "boolean", "true_false" => false, "yes_no" => true } }
      ] })
  end

  let!(:small) { create(:product, company: company, category: category, name: "Crimson Small", property_integer_1: 50, property_boolean_1: false) }
  let!(:large) { create(:product, company: company, category: category, name: "Azure Large", property_integer_1: 250, property_boolean_1: true) }

  before do
    raise "Meilisearch not reachable. Run `docker compose up -d meilisearch`." unless
      begin
        Meilisearch::Rails.client.health["status"] == "available"
      rescue StandardError
        false
      end
    Product.ms_clear_index!
    [ small, large ].each { |p| p.ms_index!(true) }

    sign_in(owner)

    page.execute_script("localStorage.clear()")
    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
      "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
      "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
      "branches" => [], "departments" => [], "roles" => []
    )
    payload = { user: JSON.parse(owner.to_json), companies: [ company_data ], enums: {}, employees: [] }
    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  after { Product.ms_clear_index! }

  scenario "renders search input and config-driven filter dropdowns" do
    visit company_products_path(company, category_id: category.id)

    expect(page).to have_field("q", wait: 10)
    expect(page).to have_select("filters[property_integer_1]", options: [ "All", "< 100", "≥ 100" ])
    expect(page).to have_select("filters[property_boolean_1]", options: [ "All", "Yes", "No" ])
  end

  scenario "keyword search via GET form narrows the table" do
    visit company_products_path(company, category_id: category.id)
    expect(page).to have_selector("tbody tr", count: 2, wait: 10)

    fill_in "q", with: "Crimson"
    click_button "Search"

    expect(page).to have_current_path(/q=Crimson/, wait: 10)
    expect(page).to have_selector("tbody tr", count: 1, wait: 10)
    expect(page).to have_content("Crimson Small")
    expect(page).to have_no_content("Azure Large")
  end

  scenario "range bucket filters results" do
    visit company_products_path(company, category_id: category.id, q: "Large")
    expect(page).to have_selector("tbody tr", count: 1, wait: 10)

    visit company_products_path(company, category_id: category.id, "filters" => { "property_integer_1" => "100:" })
    expect(page).to have_selector("tbody tr", count: 1, wait: 10)
    expect(page).to have_content("Azure Large")

    select "≥ 100", from: "filters[property_integer_1]"
    click_button "Search"
    expect(page).to have_current_path(/property_integer_1/, wait: 10)
    expect(page).to have_content("Azure Large", wait: 10)
  end

  scenario "boolean filter" do
    visit company_products_path(company, category_id: category.id, "filters" => { "property_boolean_1" => "true" })
    expect(page).to have_selector("tbody tr", count: 1, wait: 10)
    expect(page).to have_content("Azure Large")
  end

  scenario "search prefills from URL after page reload" do
    visit company_products_path(company, category_id: category.id, q: "Crimson")
    expect(page).to have_field("q", with: "Crimson", wait: 10)
    select "< 100", from: "filters[property_integer_1]"
    expect(page).to have_select("filters[property_integer_1]", selected: "< 100")
  end

  scenario "pages with no search config render the plain table" do
    table_config.update!(metadata: { "columns" => [
      { "key" => "name", "name" => "Name", "visible" => true }
    ] })
    # re-seed cache with updated config
    page.execute_script("localStorage.clear()")
    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
      "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
      "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
      "branches" => [], "departments" => [], "roles" => []
    )
    payload = { user: JSON.parse(owner.to_json), companies: [ company_data ], enums: {}, employees: [] }
    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)

    visit company_products_path(company, category_id: category.id)
    expect(page).to have_selector("tbody tr", wait: 10)
    expect(page).to have_no_field("q")
    expect(page).to have_no_css('select[name="filters[property_integer_1]"]')
  end
end
