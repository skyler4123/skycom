require "rails_helper"

RSpec.feature "Companies::Facilities Management", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company) }

  let!(:facility) { create(:facility, company: company, branch: branch) }

  before do
    sign_in(owner)
  end

  scenario "index page loads and displays facilities table" do
    visit company_facilities_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('th', text: 'Category')
    expect(page).to have_selector('thead th', minimum: 2)
    expect(page).to have_selector('tbody tr')
    expect(page).to have_content(facility.name)
  end

  scenario "edit button links to edit page for facility" do
    visit company_facilities_path(company)
    expect(page).to have_selector('table', wait: 10)

    edit_link = find("a[href*='/edit']", match: :first)
    expect(edit_link).to be_present
  end

  scenario "name link goes to show page" do
    visit company_facilities_path(company)
    expect(page).to have_selector('table', wait: 10)

    click_link facility.name, match: :first
    expect(page).to have_current_path(/facilities\/#{facility.id}$/, wait: 10)
    expect(page).to have_content(facility.name)
  end

  scenario "displays facility workflow status as badge" do
    visit company_facilities_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('span.rounded-full', wait: 10)
  end

  describe "table title" do
    let(:test_category) do
      Seed::CategoryService.create(company: company, name: "Test Category", resource_name: "facilities")
    end

    let!(:test_table_config) do
      test_category.default_property_mapping.table_configs.destroy_all
      tc = TableConfig.create!(
        company: company,
        category: test_category,
        property_mapping: test_category.default_property_mapping,
        resource_name: "facilities",
        columns_metadata: [
          { "key" => "name", "label" => "Name", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
          { "key" => "code", "label" => "Code", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} }
        ]
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
      visit company_facilities_path(company, category_id: test_category.id)
      expect(page).to have_selector('table', wait: 10)

      expect(page).to have_selector('h2', text: /Facilities - Test Category/)
    end

    scenario "edit icon links to table config edit page" do
      visit company_facilities_path(company, category_id: test_category.id)
      expect(page).to have_selector('table', wait: 10)

      edit_link = find("a[href*='/table_configs/#{test_table_config.id}/edit']", match: :first)
      expect(edit_link).to be_present
    end
  end
end
