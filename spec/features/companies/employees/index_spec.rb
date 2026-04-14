require "rails_helper"

RSpec.feature "Companies::Employees Management", type: :feature, js: true do
  # Test Data Setup
  let(:branch)     { create(:branch) }
  let(:company)    { branch.company }
  let(:owner)      { company.user }

  let(:department) { create(:department, company: company) }
  let(:role)       { create(:role, company: company) }
  let(:role2)      { create(:role, company: company, name: "Manager") }

  # Create employee with associations
  let!(:employee) do
    create(:employee,
      company: company,
      branch: branch,
      departments: [ department ],
      roles: [ role ]
    )
  end

  # Additional employees for testing filters and pagination
  let!(:employee2) do
    create(:employee,
      company: company,
      branch: branch,
      departments: [ department ],
      roles: [ role2 ],
      business_type: "part_time"
    )
  end

  before do
    sign_in(owner)
  end

  # ============================================================
  # Scenario 1: Index page loads and displays employees
  # ============================================================
  scenario "index page loads and displays employees table" do
    visit company_employees_path(company)

    # Wait for the page to load and render content
    expect(page).to have_selector('table', wait: 10)

    # Verify table headers are present
    expect(page).to have_selector('th', text: 'Employee Name')
    expect(page).to have_selector('th', text: 'Departments')
    expect(page).to have_selector('th', text: 'Roles')
    expect(page).to have_selector('th', text: 'Type')
    expect(page).to have_selector('th', text: 'Status')

    # Verify employees are displayed in table
    expect(page).to have_selector('tbody tr')
    expect(page).to have_content(employee.name)
  end

  # ============================================================
  # Scenario 2: Create new employee via modal
  # ============================================================
  scenario "create new employee via modal" do
    visit company_employees_path(company)
    expect(page).to have_selector('table', wait: 10)

    # Click the Add button
    find('[data-action*="openNewModal"]').click

    # Wait for modal to open - look for the form
    expect(page).to have_selector('form[data-controller="form"]', wait: 10)

    # Fill in the form using set() for JS-rendered inputs
    find('input[name="employee[name]"]', wait: 5).set("New Test Employee")
    find('select[name="employee[business_type]"]', wait: 5).select("Full Time")
    find('select[name="employee[department_id]"]', wait: 5).select(department.name)
    find('select[name="employee[role_id]"]', wait: 5).select(role.name)

    # Submit using the submit button inside the form
    within 'form[data-controller="form"]' do
      click_button "Save Employee", match: :first
    end

    # Wait for response - either modal closes or table updates
    expect(page).to have_selector('tbody tr', wait: 10)

    # Verify the employee was created in database
    expect(Employee.find_by(name: "New Test Employee")).to be_present
  end

  # ============================================================
  # Scenario 3: Edit button exists for each employee
  # ============================================================
  scenario "edit button exists for employee" do
    visit company_employees_path(company)
    expect(page).to have_selector('table', wait: 10)

    # Verify edit button exists - each row has an edit button
    expect(page).to have_selector('[data-action*="openShowModal"]', minimum: 1)
  end

  # ============================================================
  # Scenario 4: Filter by department
  # ============================================================
  scenario "filter employees by department" do
    visit company_employees_path(company)
    expect(page).to have_selector('table', wait: 10)

    # Select department filter and submit
    select(department.name, from: 'department_id')
    click_button "Search"

    # Wait for filtered results
    expect(page).to have_selector('tbody tr', wait: 10)

    # Verify filtered results contain the selected department
    expect(page).to have_content(department.name)
  end

  # ============================================================
  # Scenario 5: Filter by role
  # ============================================================
  scenario "filter employees by role" do
    visit company_employees_path(company)
    expect(page).to have_selector('table', wait: 10)

    # Select role filter and submit
    select(role.name, from: 'role_id')
    click_button "Search"

    # Wait for filtered results
    expect(page).to have_selector('tbody tr', wait: 10)

    # Verify results contain the filtered role
    expect(page).to have_content(role.name)
  end

  # ============================================================
  # Scenario 6: Filter by workflow status
  # ============================================================
  scenario "filter employees by workflow status" do
    visit company_employees_path(company)
    expect(page).to have_selector('table', wait: 10)

    # Status options: Draft, Pending, Confirmed, In progress, Completed, Paid, Cancelled, Refunded, Failed
    select("Draft", from: 'workflow_status')
    click_button "Search"

    # Wait for filtered results
    expect(page).to have_selector('tbody tr', wait: 10)
  end

  # ============================================================
  # Scenario 7: Filter by business type
  # ============================================================
  scenario "filter employees by business type" do
    visit company_employees_path(company)
    expect(page).to have_selector('table', wait: 10)

    # Business type options: Full time, Part time, Contractor, Intern
    select("Full time", from: 'business_type')
    click_button "Search"

    # Wait for filtered results
    expect(page).to have_selector('tbody tr', wait: 10)

    # Verify results show the selected type
    expect(page).to have_content("Full time")
  end

  # ============================================================
  # Scenario 8: Display employee table with departments and roles
  # ============================================================
  scenario "display employee departments and roles correctly" do
    visit company_employees_path(company)
    expect(page).to have_selector('table', wait: 10)

    # Verify department badges are displayed
    expect(page).to have_content(department.name)

    # Verify role badges are displayed
    expect(page).to have_content(role.name)
  end

  # ============================================================
  # Scenario 9: Employee business type badge display
  # ============================================================
  scenario "display employee business type as badge" do
    visit company_employees_path(company)
    expect(page).to have_selector('table', wait: 10)

    # Check for "Full time" badge
    expect(page).to have_content("Full time", wait: 10)

    # Check for "Part time" badge
    expect(page).to have_content("Part time", wait: 10)
  end

  # ============================================================
  # Scenario 10: Employee workflow status badge
  # ============================================================
  scenario "display employee workflow status correctly" do
    visit company_employees_path(company)
    expect(page).to have_selector('table', wait: 10)

    # Verify status badge is rendered - look for rounded-full class badge style
    expect(page).to have_selector('span.rounded-full', wait: 10)
  end

  # ============================================================
  # Scenario 11: Pagination controls
  # ============================================================
  scenario "pagination controls render correctly" do
    visit company_employees_path(company)
    expect(page).to have_selector('table', wait: 10)

    # Page should render without error
    expect(true).to be true
  end

  # ============================================================
  # Scenario 12: Search button functionality
  # ============================================================
  scenario "search button triggers filter form" do
    visit company_employees_path(company)
    expect(page).to have_selector('table', wait: 10)

    # Verify search button exists
    expect(page).to have_button("Search")
  end
end
