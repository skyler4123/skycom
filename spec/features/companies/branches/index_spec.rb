require "rails_helper"

RSpec.feature "Companies::Branches Management", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }

  let!(:branch2) { create(:branch, company: company) }

  let!(:default_category) do
    Seed::CategoryService.find_or_create_for(company: company, resource_name: "branches")
  end

  let!(:default_table_config) do
    default_category.default_property_mapping.table_configs.destroy_all
    TableConfig.create!(
      company: company,
      category: default_category,
      property_mapping: default_category.default_property_mapping,
      resource_name: "branches",
      columns_metadata: [
        { "key" => "name", "label" => "Branch Name", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
        { "key" => "code", "label" => "Code", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
        { "key" => "business_type", "label" => "Type", "visible" => true, "sortable" => true, "align" => "center", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
        { "key" => "workflow_status", "label" => "Status", "visible" => true, "sortable" => true, "align" => "center", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} }
      ]
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

  scenario "index page loads and displays branches table" do
    visit company_branches_path(company)

    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('th', text: 'Branch Name')
    expect(page).to have_selector('th', text: 'Category')
    expect(page).to have_selector('th', text: 'Type')
    expect(page).to have_selector('th', text: 'Status')

    expect(page).to have_selector('tbody tr')
    expect(page).to have_content(branch.name)
  end

  scenario "edit button links to show page for branch" do
    visit company_branches_path(company)
    expect(page).to have_selector('table', wait: 10)

    edit_link = find("a[href*='/branches/#{branch.id}']", match: :first)
    expect(edit_link).to be_present
  end

  scenario "filter by category updates URL and filters table" do
    category = Seed::CategoryService.create(company: company, name: "Test Category", resource_name: "branches")
    branch.update!(category: category, property_mapping: category.default_property_mapping)
    visit company_branches_path(company)
    expect(page).to have_selector('table', wait: 10)

    select(category.name, from: 'category_id')
    click_button "Search"

    expect(page).to have_current_path(/category_id=#{category.id}/)
    expect(page).to have_selector('tbody tr', wait: 10)
  end

  scenario "display branch workflow status as badge" do
    visit company_branches_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('span.rounded-full', wait: 10)
  end

  # =========================================================================
  # SCENARIO: Config Table button appears when table config exists
  # =========================================================================
  scenario "shows Config Table button when table config exists" do
    visit company_branches_path(company, category_id: default_category.id)
    expect(page).to have_selector('table', wait: 10)

    config_link = find("a[href*='/table_configs/#{default_table_config.id}/edit']", match: :first)
    expect(config_link).to be_present
    expect(config_link.text).to include("Config Table")
  end

  # =========================================================================
  # SCENARIO: Config Table button links to edit page
  # =========================================================================
  scenario "Config Table button navigates to table config edit page" do
    visit company_branches_path(company, category_id: default_category.id)
    expect(page).to have_selector('table', wait: 10)

    click_link "Config Table", match: :first
    expect(page).to have_current_path(/table_configs\/#{default_table_config.id}\/edit/, wait: 10)
  end

end
