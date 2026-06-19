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
end
