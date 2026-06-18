require "rails_helper"

RSpec.feature "Companies::Departments Management", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }

  let!(:department) do
    create(:department, company: company, business_type: "sales")
  end

  let!(:department2) do
    create(:department, company: company, business_type: "marketing")
  end

  let!(:default_category) do
    Seed::CategoryService.find_or_create_for(company: company, resource_name: "departments")
  end

  let!(:default_table_config) do
    TableConfig.create!(
      company: company,
      category: default_category,
      property_mapping: default_category.default_property_mapping,
      resource_name: "departments",
      columns_metadata: [
        { "key" => "name", "label" => "Department Name", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
        { "key" => "code", "label" => "Code", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
        { "key" => "workflow_status", "label" => "Status", "visible" => true, "sortable" => true, "align" => "center", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} }
      ]
    )
  end

  before do
    department2.update_column(:workflow_status, 1)

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

  scenario "index page loads and displays departments table" do
    visit company_departments_path(company)

    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('th', text: 'Department Name')
    expect(page).to have_selector('th', text: 'Status')

    expect(page).to have_selector('tbody tr')
    expect(page).to have_content(department.name)
  end

  scenario "edit button links to edit page for department" do
    visit company_departments_path(company)
    expect(page).to have_selector('table', wait: 10)

    edit_link = find("a[href*='/departments/#{department.id}/edit']", match: :first)
    expect(edit_link).to be_present
  end

  scenario "filter by category updates URL and filters table" do
    category = Seed::CategoryService.create(company: company, name: "Test Category", resource_name: "departments")
    department.update!(category: category, property_mapping: category.default_property_mapping)
    visit company_departments_path(company)
    expect(page).to have_selector('table', wait: 10)

    select(category.name, from: 'category_id')
    click_button "Search"

    expect(page).to have_current_path(/category_id=#{category.id}/)
    expect(page).to have_selector('tbody tr', wait: 10)
  end

  scenario "display department workflow status as badge" do
    visit company_departments_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('span.rounded-full', wait: 10)
  end
end
