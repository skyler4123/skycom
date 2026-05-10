require "rails_helper"

RSpec.feature "Companies::Departments Management", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }

  let!(:department) do
    create(:department,
      company: company,
      business_type: "sales"
    )
  end

  let!(:department2) do
    create(:department,
      company: company,
      business_type: "marketing",
      workflow_status: "pending"
    )
  end

  before do
    sign_in(owner)
  end

  scenario "index page loads and displays departments table" do
    visit company_departments_path(company)

    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('th', text: 'Department Name')
    expect(page).to have_selector('th', text: 'Type')
    expect(page).to have_selector('th', text: 'Status')

    expect(page).to have_selector('tbody tr')
    expect(page).to have_content(department.name)
  end



  scenario "create new department via modal" do
    visit company_departments_path(company)
    expect(page).to have_selector('table', wait: 10)

    find('[data-action*="openNewModal"]').click

    expect(page).to have_selector('form[data-action*="handleSubmit"]', wait: 10)

    expect(page).to have_selector('input[name="department[name]"]', wait: 5)
    fill_in 'department[name]', with: 'New Test Department'
    fill_in 'department[email]', with: 'test@department.com'
    select 'Operations', from: 'department[business_type]'

    click_button "Save Department"

    expect(page).to have_content("created successfully", wait: 10)
    expect(page).to have_selector('tbody tr', wait: 10)

    expect(Department.find_by(name: "New Test Department")).to be_present
  end

  scenario "edit button opens show modal for department" do
    visit company_departments_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('[data-action*="openShowModal"]', minimum: 1)
  end

  scenario "search triggers form submission and filters results" do
    visit company_departments_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_button("Search")

    click_button "Search"

    expect(page).to have_selector('tbody tr', wait: 10)
  end

  scenario "filter by business type updates URL and filters table" do
    visit company_departments_path(company)
    expect(page).to have_selector('table', wait: 10)

    select("Marketing", from: 'business_type')
    click_button "Search"

    expect(page).to have_current_path(/business_type=marketing/)

    expect(page).to have_selector('tbody tr', wait: 10)
    expect(page).to have_content("Marketing")
  end



  scenario "display department business type as badge" do
    visit company_departments_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_content("Sales", minimum: 1)
    expect(page).to have_content("Marketing", minimum: 1)
  end

  scenario "display department workflow status as badge" do
    visit company_departments_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('span.rounded-full', wait: 10)
  end



  scenario "clear filters resets URL and shows all departments" do
    visit company_departments_path(company, business_type: "marketing")
    expect(page).to have_selector('table', wait: 10)

    click_button "Search"

    expect(page).to have_current_path(/business_type=marketing/)

    select("All Types", from: 'business_type')
    click_button "Search"

    expect(page).to have_current_path(/business_type=/)
  end

  scenario "update department name via show modal" do
    visit company_departments_path(company)
    expect(page).to have_selector('table', wait: 10)

    target_row = find('tbody tr', text: department.name)
    target_row.find('[data-action*="openShowModal"]').click

    expect(page).to have_selector('.swal2-container', wait: 10)

    editable_name_field = find('[data-controller="editable"]', match: :first)
    editable_name_field.click

    expect(page).to have_selector('.editable-input', wait: 5)

    editable_name_field.find('.editable-input').fill_in(with: 'Updated Department Name')

    accept_confirm do
      editable_name_field.find('.editable-input').send_keys :enter
    end

    expect(page).to have_selector('tbody tr', wait: 10)
    expect(Department.find_by(id: department.id).name).to eq("Updated Department Name")
  end

  scenario "update department description via show modal" do
    visit company_departments_path(company)
    expect(page).to have_selector('table', wait: 10)

    target_row = find('tbody tr', text: department.name)
    target_row.find('[data-action*="openShowModal"]').click

    expect(page).to have_selector('.swal2-container', wait: 10)

    all_editable = all('[data-controller="editable"]')
    desc_editable = all_editable[1]
    desc_editable.click

    expect(page).to have_selector('.editable-input', wait: 5)

    desc_editable.find('.editable-input').fill_in(with: 'Updated description for this department')

    accept_confirm do
      desc_editable.find('.editable-input').send_keys :enter
    end

    expect(page).to have_selector('tbody tr', wait: 10)
    expect(Department.find_by(id: department.id).description).to eq("Updated description for this department")
  end
end
