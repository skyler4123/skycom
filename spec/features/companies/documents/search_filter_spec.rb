# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::Documents dynamic search/filter", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "documents") }
  let(:document_group) { Seed::DocumentGroupService.create(company: company) }

  let!(:table_config) do
    category.default_property_mapping.table_configs.destroy_all
    TableConfig.create!(company: company, category: category,
      property_mapping: category.default_property_mapping, resource_name: "documents",
      metadata: { "columns" => [
        { "key" => "name", "name" => "Name", "visible" => true, "search" => true },
        { "key" => "property_integer_1", "name" => "Pages", "visible" => true,
          "filter" => { "type" => "range", "active" => true, "buckets" => [ [ nil, 100 ], [ 100, nil ] ] } }
      ] })
  end

  let!(:small) do
    Seed::DocumentService.create(company: company, category: category,
      document_group: document_group, name: "Crimson Small", title: "Crimson Small",
      property_integer_1: 50)
  end
  let!(:large) do
    Seed::DocumentService.create(company: company, category: category,
      document_group: document_group, name: "Azure Large", title: "Azure Large",
      property_integer_1: 250)
  end

  before do
    raise "Meilisearch not reachable. Run `docker compose up -d meilisearch`." unless
      begin
        Meilisearch::Rails.client.health["status"] == "available"
      rescue StandardError
        false
      end
    Document.ms_clear_index!
    [ small, large ].each { |d| d.ms_index!(true) }

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

  after { Document.ms_clear_index! }

  scenario "renders search input and filter dropdown from TableConfig" do
    visit company_documents_path(company, category_id: category.id)

    expect(page).to have_field("q", wait: 10)
    expect(page).to have_select("filters[property_integer_1]", options: [ "All", "< 100", "≥ 100" ])
  end

  scenario "keyword search via GET form narrows the table" do
    visit company_documents_path(company, category_id: category.id, q: "Crimson")

    expect(page).to have_selector("tbody tr", count: 1, wait: 10)
    expect(page).to have_content("Crimson Small")
    expect(page).to have_no_content("Azure Large")
  end

  scenario "range bucket filters results" do
    visit company_documents_path(company, category_id: category.id, "filters" => { "property_integer_1" => "100:" })

    expect(page).to have_selector("tbody tr", count: 1, wait: 10)
    expect(page).to have_content("Azure Large")
  end
end
