require "rails_helper"

RSpec.feature "Companies::Employees Management", type: :feature, js: true do
  let(:branch)     { create(:branch) }
  let(:company)   { branch.company }
  let(:owner)     { company.user }

  let(:department) { create(:department, company: company) }
  let(:department2) { create(:department, company: company, name: "Engineering") }
  let(:role)       { create(:role, company: company) }
  let(:role2)     { create(:role, company: company, name: "Manager") }

  let!(:employee) do
    emp = create(:employee, company: company, branch: branch, business_type: "full_time")
    create(:department_appointment, company: company, appoint_to: emp, department: department)
    create(:role_appointment, company: company, appoint_to: emp, role: role)
    emp
  end

  let!(:employee2) do
    emp = create(:employee, company: company, branch: branch, business_type: "part_time")
    create(:department_appointment, company: company, appoint_to: emp, department: department2)
    create(:role_appointment, company: company, appoint_to: emp, role: role2)
    emp
  end

  before do
    sign_in(owner)
  end

  scenario "index page loads and displays employees table" do
    visit company_employees_path(company)

    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('th', text: 'Employee Name')
    expect(page).to have_selector('th', text: 'Category')
    expect(page).to have_selector('th', text: 'Code')
    expect(page).to have_selector('th', text: 'Type')
    expect(page).to have_selector('th', text: 'Status')

    expect(page).to have_selector('tbody tr')
    expect(page).to have_content(employee.name)
  end

  scenario "edit button links to edit page for employee" do
    visit company_employees_path(company)
    expect(page).to have_selector('table', wait: 10)

    edit_link = find("a[href*='/edit']", match: :first)
    expect(edit_link).to be_present
  end

  scenario "name link goes to show page" do
    visit company_employees_path(company)
    expect(page).to have_selector('table', wait: 10)

    click_link employee.name, match: :first
    expect(page).to have_current_path(/employees\/#{employee.id}$/, wait: 10)
    expect(page).to have_content(employee.name)
  end

  scenario "displays employee workflow status as badge" do
    visit company_employees_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('span.rounded-full', wait: 10)
  end

  scenario "display employee business type as badge" do
    visit company_employees_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_content("Full time", minimum: 1)
    expect(page).to have_content("Part time", minimum: 1)
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
      test_category.default_property_mapping.table_configs.destroy_all
      tc = TableConfig.create!(
        company: company,
        category: test_category,
        property_mapping: test_category.default_property_mapping,
        resource_name: "employees",
        columns_metadata: [
          { "key" => "name", "name" => "Name", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
          { "key" => "code", "name" => "Code", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} }
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
