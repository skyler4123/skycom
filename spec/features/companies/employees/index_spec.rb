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
    create(:employee,
      company: company,
      branch: branch,
      departments: [ department ],
      roles: [ role ],
      business_type: "full_time"
    )
  end

  let!(:employee2) do
    create(:employee,
      company: company,
      branch: branch,
      departments: [ department2 ],
      roles: [ role2 ],
      business_type: "part_time"
    )
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

    expect(page).to have_selector('form[data-controller="form"]', wait: 10)

    expect(page).to have_selector('input[name="employee[name]"]', wait: 5)
    fill_in 'employee[name]', with: 'New Test Employee'
    select 'Full Time', from: 'employee[business_type]'

    click_button 'Save Employee'

    expect(page).to have_selector('tbody tr', wait: 10)

    expect(Employee.find_by(name: "New Test Employee")).to be_present
  end

  scenario "edit button opens show modal for employee" do
    visit company_employees_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('[data-action*="openShowModal"]', minimum: 1)
  end

  scenario "search triggers form submission and filters results" do
    visit company_employees_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_button("Search")

    click_button "Search"

    expect(page).to have_selector('tbody tr', wait: 10)
  end

  scenario "filter by department updates URL and filters table" do
    visit company_employees_path(company)
    expect(page).to have_selector('table', wait: 10)

    select(department.name, from: 'department_id')
    click_button "Search"

    expect(page).to have_current_path(/department_id=#{department.id}/)

    expect(page).to have_selector('tbody tr', wait: 10)
    expect(page).to have_content(department.name)
  end

  scenario "filter by role updates URL and filters table" do
    visit company_employees_path(company)
    expect(page).to have_selector('table', wait: 10)

    select(role.name, from: 'role_id')
    click_button "Search"

    expect(page).to have_current_path(/role_id=#{role.id}/)

    expect(page).to have_selector('tbody tr', wait: 10)
    expect(page).to have_content(role.name)
  end

  scenario "filter by workflow status updates URL and filters table" do
    employee.update!(workflow_status: "draft")
    visit company_employees_path(company)
    expect(page).to have_selector('table', wait: 10)

    select("Draft", from: 'workflow_status')
    click_button "Search"

    expect(page).to have_current_path(/workflow_status=draft/)

    expect(page).to have_selector('tbody tr', wait: 10)
  end

  scenario "filter by business type updates URL and filters table" do
    visit company_employees_path(company)
    expect(page).to have_selector('table', wait: 10)

    select("Full time", from: 'business_type')
    click_button "Search"

    expect(page).to have_current_path(/business_type=full_time/)

    expect(page).to have_selector('tbody tr', wait: 10)
    expect(page).to have_content("Full time")
  end

  scenario "clear filters resets URL and shows all employees" do
    visit company_employees_path(company, department_id: department.id)
    expect(page).to have_selector('table', wait: 10)

    click_button "Search"

    expect(page).to have_current_path(/department_id=#{department.id}/)

    select("All Departments", from: 'department_id')
    click_button "Search"

    expect(page).to have_current_path(/department_id=/)
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
