require "rails_helper"

RSpec.feature "Companies::Services Management", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:owner) { company.user }

  let!(:default_category) do
    category = Seed::CategoryService.find_or_create_for(company: company, resource_name: "services")
    category.default_property_mapping.update!(
      metadata: { "properties" => [
        { "key" => "property_string_1", "type" => "string", "name" => "Duration" },
        { "key" => "property_integer_1", "type" => "integer", "name" => "Sessions" }
      ] }
    )
    category
  end

  let!(:service) do
    Seed::ServiceService.create(
      company: company,
      name: "Test Service 1",
      business_type: "b2b",
      workflow_status: "draft",
      category: default_category
    ).tap { |s| s.update!(property_string_1: "Premium", property_integer_1: 12) }
  end

  let!(:service2) do
    Seed::ServiceService.create(
      company: company,
      name: "Test Service 2",
      business_type: "b2c",
      workflow_status: "pending",
      category: default_category
    ).tap { |s| s.update!(property_string_1: "Basic", property_integer_1: 6) }
  end

  let!(:default_table_config) do
    default_category.default_property_mapping.table_configs.destroy_all
    TableConfig.create!(
      company: company,
      category: default_category,
      property_mapping: default_category.default_property_mapping,
      resource_name: "services",
      metadata: { "columns" => [
        { "key" => "property_string_1", "name" => "Duration", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
        { "key" => "property_integer_1", "name" => "Sessions", "visible" => true, "sortable" => true, "align" => "right", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} }
      ] }
    )
  end

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

  scenario "index page loads and displays services table" do
    visit company_services_path(company)

    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('th', text: 'Duration', wait: 10)
    expect(page).to have_selector('th', text: 'Sessions', wait: 10)

    expect(page).to have_selector('tbody tr')
    expect(page).to have_content("Premium")
  end

  scenario "edit button links to edit page for service" do
    visit company_services_path(company)
    expect(page).to have_selector('table', wait: 10)

    edit_link = find("a[href*='/services/#{service.id}/edit']", match: :first)
    expect(edit_link).to be_present
  end

  scenario "filter by category updates URL and filters table" do
    category = Seed::CategoryService.create(company: company, name: "Test Category", resource_name: "services")
    service.category = category
    service.property_mapping = category.default_property_mapping
    Seed::PropertyPopulator.populate(service)
    service.save!
    visit company_services_path(company)
    expect(page).to have_selector('table', wait: 10)

    select(category.name, from: 'category_id')
    click_button "Search"

    expect(page).to have_current_path(/category_id=#{category.id}/)
    expect(page).to have_selector('tbody tr', wait: 10)
  end

  describe "table title" do
    let(:test_category) do
      Seed::CategoryService.create(company: company, name: "Test Category", resource_name: "services")
    end

    let!(:test_table_config) do
      test_category.default_property_mapping.update!(
        metadata: { "properties" => [
          { "key" => "property_string_1", "type" => "string", "name" => "Duration" }
        ] }
      )
      test_category.default_property_mapping.table_configs.destroy_all
      tc = TableConfig.create!(
        company: company,
        category: test_category,
        property_mapping: test_category.default_property_mapping,
        resource_name: "services",
        metadata: { "columns" => [
          { "key" => "property_string_1", "name" => "Duration", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} }
        ] }
      )
      company.clear_permissions_cache
      tc
    end

    before do
      company_data = JSON.parse(company.to_json).merge(
        "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
        "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
        "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
        "branches" => [],
        "departments" => [],
        "roles" => []
      )

      page.execute_script("localStorage.clear()")
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

    scenario "shows table title with resource name and category name" do
      visit company_services_path(company, category_id: test_category.id)
      expect(page).to have_selector('table', wait: 10)

      expect(page).to have_selector('h2', text: /Services - Test Category/)
    end

    scenario "edit icon links to table config edit page" do
      visit company_services_path(company, category_id: test_category.id)
      expect(page).to have_selector('table', wait: 10)

      edit_link = find("a[href*='/table_configs/#{test_table_config.id}/edit']", match: :first)
      expect(edit_link).to be_present
    end
  end

  describe "client cache invalidation" do
    include_examples "client cache invalidation",
      resource_name: "services"
  end
end
