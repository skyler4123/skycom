# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::StockImports dynamic search/filter", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "stock_imports") }
  let(:warehouse) { create(:warehouse, company: company) }

  let!(:table_config) do
    category.default_property_mapping.table_configs.destroy_all
    TableConfig.create!(company: company, category: category,
      property_mapping: category.default_property_mapping, resource_name: "stock_imports",
      metadata: { "columns" => [
        { "key" => "name", "name" => "Name", "visible" => true, "search" => true },
        { "key" => "quantity", "name" => "Quantity", "visible" => true,
          "filter" => { "type" => "range", "active" => true, "buckets" => [ [ nil, 100 ], [ 100, nil ] ] } }
      ] })
  end

  let!(:small) do
    product = create(:product, company: company, name: "Crimson Product")
    create(:stock_import, company: company, category: category, warehouse: warehouse, product: product,
      name: "Crimson Small", quantity: 50)
  end
  let!(:large) do
    product = create(:product, company: company, name: "Azure Product")
    create(:stock_import, company: company, category: category, warehouse: warehouse, product: product,
      name: "Azure Large", quantity: 250)
  end

  before do
    raise "Meilisearch not reachable. Run `docker compose up -d meilisearch`." unless
      begin
        Meilisearch::Rails.client.health["status"] == "available"
      rescue StandardError
        false
      end
    StockImport.ms_clear_index!
    [ small, large ].each { |s| s.ms_index!(true) }

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

  after { StockImport.ms_clear_index! }

  scenario "renders search input and filter dropdown from TableConfig" do
    visit company_stock_imports_path(company, category_id: category.id)

    expect(page).to have_field("q", wait: 10)
    expect(page).to have_select("filters[quantity]", options: [ "All", "< 100", "≥ 100" ])
  end

  scenario "keyword search via GET form narrows the table" do
    visit company_stock_imports_path(company, category_id: category.id, q: "Crimson")

    expect(page).to have_selector("tbody tr", count: 1, wait: 10)
    expect(page).to have_content("Crimson Small")
    expect(page).to have_no_content("Azure Large")
  end

  scenario "range bucket filters results on the quantity metric" do
    visit company_stock_imports_path(company, category_id: category.id, "filters" => { "quantity" => "100:" })

    expect(page).to have_selector("tbody tr", count: 1, wait: 10)
    expect(page).to have_content("Azure Large")
  end
end
