require "rails_helper"

RSpec.feature "Companies::Employees Management", type: :feature, js: true do
  let(:branch)     { create(:branch) }
  let(:company)   { branch.company }
  let(:owner)     { company.user }

  let(:department) { create(:department, company: company) }
  let(:department2) { create(:department, company: company, name: "Engineering") }
  let(:role)       { create(:role, company: company) }
  let(:role2)     { create(:role, company: company, name: "Manager") }

  let!(:default_category) do
    category = Seed::CategoryService.find_or_create_for(company: company, resource_name: "employees")
    category.default_property_mapping.update!(
      metadata: { "properties" => [
        { "key" => "property_string_1", "type" => "string", "name" => "Certification" },
        { "key" => "property_integer_1", "type" => "integer", "name" => "Weekly Hours" }
      ] }
    )
    category
  end

  let!(:default_table_config) do
    default_category.default_property_mapping.table_configs.destroy_all
    TableConfig.create!(
      company: company,
      category: default_category,
      property_mapping: default_category.default_property_mapping,
      resource_name: "employees",
      metadata: { "columns" => [
        { "key" => "property_string_1", "name" => "Certification", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
        { "key" => "property_integer_1", "name" => "Weekly Hours", "visible" => true, "sortable" => true, "align" => "right", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} }
      ] }
    )
  end

  let!(:employee) do
    emp = create(:employee, company: company, branch: branch, business_type: "full_time")
    create(:department_appointment, company: company, appoint_to: emp, department: department)
    create(:role_appointment, company: company, appoint_to: emp, role: role)
    emp.update!(property_string_1: "Senior", property_integer_1: 40)
    emp
  end

  let!(:employee2) do
    emp = create(:employee, company: company, branch: branch, business_type: "part_time")
    create(:department_appointment, company: company, appoint_to: emp, department: department2)
    create(:role_appointment, company: company, appoint_to: emp, role: role2)
    emp.update!(property_string_1: "Junior", property_integer_1: 20)
    emp
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

  scenario "index page loads and displays employees table" do
    visit company_employees_path(company, category_id: default_category.id)

    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('th', text: 'Certification', wait: 10)
    expect(page).to have_selector('th', text: 'Weekly Hours', wait: 10)

    expect(page).to have_selector('tbody tr')
    expect(page).to have_content("Senior")
  end

  scenario "edit button links to edit page for employee" do
    visit company_employees_path(company, category_id: default_category.id)
    expect(page).to have_selector('table', wait: 10)

    edit_link = find("a[href*='/edit']", match: :first)
    expect(edit_link).to be_present
  end

  scenario "show page displays employee departments and roles" do
    visit company_employee_path(company, employee)
    expect(page).to have_content(employee.name, wait: 10)

    expect(page).to have_content(department.name)
    expect(page).to have_content(role.name)
  end

  describe "table title" do
    let(:test_category) do
      Seed::CategoryService.create(company: company, name: "Test Category", resource_name: "employees")
    end

    let!(:test_table_config) do
      test_category.default_property_mapping.update!(
        metadata: { "properties" => [
          { "key" => "property_string_1", "type" => "string", "name" => "Certification" }
        ] }
      )
      test_category.default_property_mapping.table_configs.destroy_all
      tc = TableConfig.create!(
        company: company,
        category: test_category,
        property_mapping: test_category.default_property_mapping,
        resource_name: "employees",
        metadata: { "columns" => [
          { "key" => "property_string_1", "name" => "Certification", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} }
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
      visit company_employees_path(company, category_id: test_category.id)
      expect(page).to have_selector('table', wait: 10)

      expect(page).to have_selector('h2', text: /Employees - Test Category/)
    end

    scenario "edit icon links to table config edit page" do
      visit company_employees_path(company, category_id: test_category.id)
      expect(page).to have_selector('table', wait: 10)

      edit_link = find("a[href*='/table_configs/#{test_table_config.id}/edit']", match: :first)
      expect(edit_link).to be_present
    end
  end

  describe "client cache invalidation" do
    include_examples "client cache invalidation",
      resource_name: "employees"
  end
end
