# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::Orders dynamic search/filter", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "orders") }
  let(:customer) { create(:customer, company: company) }

  let!(:table_config) do
    category.default_property_mapping.table_configs.destroy_all
    TableConfig.create!(company: company, category: category,
      property_mapping: category.default_property_mapping, resource_name: "orders",
      metadata: { "columns" => [
        { "key" => "name", "name" => "Name", "visible" => true, "search" => true },
        { "key" => "code", "name" => "Code", "visible" => true }
      ] })
  end

  let!(:crimson) { create(:order, company: company, category: category, customer: customer, name: "Crimson Batch") }
  let!(:azure) { create(:order, company: company, category: category, customer: customer, name: "Azure Batch") }

  before do
    raise "Meilisearch not reachable. Run `docker compose up -d meilisearch`." unless
      begin
        Meilisearch::Rails.client.health["status"] == "available"
      rescue StandardError
        false
      end
    Order.ms_clear_index!
    [ crimson, azure ].each { |o| o.ms_index!(true) }

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

  after { Order.ms_clear_index! }

  scenario "search input renders first; no filter dropdowns on a keyword-only config" do
    visit company_orders_path(company, category_id: category.id)

    expect(page).to have_field("q", wait: 10)
    expect(page).to have_css("form div.flex.flex-wrap > div:first-child input[name='q']", wait: 10)
    expect(page).to have_no_css("select[name^='filters[']")
  end

  scenario "keyword search narrows the table" do
    visit company_orders_path(company, category_id: category.id, q: "Crimson")

    expect(page).to have_selector("tbody tr", count: 1, wait: 10)
    expect(page).to have_content("Crimson Batch")
    expect(page).to have_no_content("Azure Batch")
  end
end
