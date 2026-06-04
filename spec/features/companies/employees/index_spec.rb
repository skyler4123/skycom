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
    expect(page).to have_selector('th', text: 'Departments')
    expect(page).to have_selector('th', text: 'Roles')
    expect(page).to have_selector('th', text: 'Type')
    expect(page).to have_selector('th', text: 'Status')

    expect(page).to have_selector('tbody tr')
    expect(page).to have_content(employee.name)
  end

  scenario "create new employee via modal" do
    visit company_employees_path(company)
    expect(page).to have_selector('table', wait: 10)

    find('[data-action*="openNewModal"]').click

    expect(page).to have_selector('form[data-action*="handleSubmit"]', wait: 10)

    expect(page).to have_selector('input[name="employee[name]"]', wait: 5)
    fill_in 'employee[name]', with: 'New Test Employee'
    select 'Full Time', from: 'employee[business_type]'

    begin
      click_button "Save Employee"
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      visit company_employees_path(company)
      expect(page).to have_selector('table', wait: 10)

      find('[data-action*="openNewModal"]').click

      expect(page).to have_selector('form[data-action*="handleSubmit"]', wait: 10)

      expect(page).to have_selector('input[name="employee[name]"]', wait: 5)
      fill_in 'employee[name]', with: 'New Test Employee'
      select 'Full Time', from: 'employee[business_type]'
      click_button "Save Employee"
    end
    expect(page).to have_selector('tbody tr', wait: 10)

    expect(Employee.find_by(name: "New Test Employee")).to be_present
  end

  scenario "edit button opens show modal for employee" do
    visit company_employees_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('[data-action*="openShowModal"]', minimum: 1)
  end

  scenario "delete button removes employee from table" do
    visit company_employees_path(company)
    expect(page).to have_selector('table', wait: 10)

    target_row = find('tbody tr', text: employee.name)
    target_row.find('[data-action*="openShowModal"]').click

    expect(page).to have_selector('.swal2-container', wait: 10)

    click_button "Delete"

    accept_alert

    expect(page).to have_content("Employee deleted successfully!", wait: 10)

    employee.reload
    expect(employee.discarded?).to be_truthy
  end

  scenario "filter by category updates URL and filters table" do
    category = Seed::CategoryService.create(company: company, name: "Test Category", resource_name: "employees")
    employee.update!(category: category, property_mapping: category.property_mapping)
    visit company_employees_path(company)
    expect(page).to have_selector('table', wait: 10)

    select(category.name, from: 'category_id')
    click_button "Search"

    expect(page).to have_current_path(/category_id=#{category.id}/)
    expect(page).to have_selector('tbody tr', wait: 10)
  end

  scenario "display employee departments as badges" do
    visit company_employees_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_content(department.name)
  end

  scenario "display employee roles as badges" do
    visit company_employees_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_content(role.name)
  end

  scenario "display employee business type as badge" do
    visit company_employees_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_content("Full time", minimum: 1)
    expect(page).to have_content("Part time", minimum: 1)
  end

  scenario "display employee workflow status as badge" do
    visit company_employees_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('span.rounded-full', wait: 10)
  end
end
