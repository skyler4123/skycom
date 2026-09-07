# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::Employees dynamic search/filter", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company, discarded_at: nil) }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "employees") }

  let!(:table_config) do
    category.default_property_mapping.table_configs.destroy_all
    TableConfig.create!(company: company, category: category,
      property_mapping: category.default_property_mapping, resource_name: "employees",
      metadata: { "columns" => [
        { "key" => "name", "name" => "Name", "visible" => true, "search" => true },
        { "key" => "property_integer_1", "name" => "KPI Target", "visible" => true,
          "filter" => { "type" => "range", "active" => true, "buckets" => [ [ nil, 100 ], [ 100, nil ] ] } }
      ] })
  end

  let!(:small) { create(:employee, company: company, category: category, branch: branch, name: "Crimson Small", property_integer_1: 50) }
  let!(:large) { create(:employee, company: company, category: category, branch: branch, name: "Crimson Large", property_integer_1: 250) }
  let!(:ghost) { create(:employee, company: company, category: category, branch: branch, name: "Crimson Ghost", property_integer_1: 250) }

  before do
    raise "Meilisearch not reachable. Run `docker compose up -d meilisearch`." unless
      begin
        Meilisearch::Rails.client.health["status"] == "available"
      rescue StandardError
        false
      end
    Employee.ms_clear_index!
    [ small, large, ghost ].each { |e| e.ms_index!(true) }
    ghost.discard! # after_commit suppressed — the doc stays indexed, exactly like production reindex-on-discard

    sign_in(owner)

    page.execute_script("localStorage.clear()")
    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
      "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
      "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
      "branches" => [ branch ].map { |b| JSON.parse(b.to_json) },
      "departments" => [], "roles" => []
    )
    payload = { user: JSON.parse(owner.to_json), companies: [ company_data ], enums: {}, employees: [] }
    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  after { Employee.ms_clear_index! }

  scenario "renders search input, Branch select and range dropdown" do
    visit company_employees_path(company, category_id: category.id)

    expect(page).to have_field("q", wait: 10)
    expect(page).to have_css("form div.flex.flex-wrap > div:first-child input[name='q']", wait: 10)
    expect(page).to have_select("branch_id")
    expect(page).to have_select("filters[property_integer_1]", options: [ "All", "< 100", "≥ 100" ])
  end

  scenario "keyword search excludes the discarded employee (kept scope survives the search path)" do
    visit company_employees_path(company, category_id: category.id, q: "Crimson")

    expect(page).to have_selector("tbody tr", count: 2, wait: 10)
    expect(page).to have_content("Crimson Small")
    expect(page).to have_content("Crimson Large")
    expect(page).to have_no_content("Crimson Ghost")
  end

  scenario "range bucket filters results" do
    visit company_employees_path(company, category_id: category.id, "filters" => { "property_integer_1" => "100:" })

    expect(page).to have_selector("tbody tr", count: 1, wait: 10)
    expect(page).to have_content("Crimson Large")
  end
end
