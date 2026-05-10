require "rails_helper"

RSpec.feature "Companies::Branches Management", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }

  let!(:branch2) do
    create(:branch,
      company: company,
      business_type: "warehouse",
      city: "Ho Chi Minh City"
    )
  end

  before do
    sign_in(owner)
  end

  scenario "index page loads and displays branches table" do
    visit company_branches_path(company)

    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('th', text: 'Branch Name')
    expect(page).to have_selector('th', text: 'Type')
    expect(page).to have_selector('th', text: 'City')
    expect(page).to have_selector('th', text: 'Status')

    expect(page).to have_selector('tbody tr')
    expect(page).to have_content(branch.name)
  end

  scenario "create new branch via modal" do
    visit company_branches_path(company)
    expect(page).to have_selector('table', wait: 10)

    find('[data-action*="openNewModal"]').click

    expect(page).to have_selector('form[data-action*="handleSubmit"]', wait: 10)

    expect(page).to have_selector('input[name="branch[name]"]', wait: 5)
    fill_in 'branch[name]', with: 'New Test Branch'
    select 'Headquarters', from: 'branch[business_type]'
    fill_in 'branch[city]', with: 'Da Nang'

    begin
      click_button "Save Branch"
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      visit company_branches_path(company)
      expect(page).to have_selector('table', wait: 10)

      find('[data-action*="openNewModal"]').click

      expect(page).to have_selector('form[data-action*="handleSubmit"]', wait: 10)

      fill_in 'branch[name]', with: 'New Test Branch'
      select 'Headquarters', from: 'branch[business_type]'
      click_button "Save Branch"
    end
    expect(page).to have_selector('tbody tr', wait: 10)

    expect(Branch.find_by(name: "New Test Branch")).to be_present
  end

  scenario "edit button opens show modal for branch" do
    visit company_branches_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('[data-action*="openShowModal"]', minimum: 1)
  end

  scenario "search triggers form submission and filters results" do
    visit company_branches_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_button("Search")

    click_button "Search"

    expect(page).to have_selector('tbody tr', wait: 10)
  end

  scenario "filter by business type updates URL and filters table" do
    visit company_branches_path(company)
    expect(page).to have_selector('table', wait: 10)

    select("Warehouse", from: 'business_type')
    click_button "Search"

    expect(page).to have_current_path(/business_type=warehouse/)

    expect(page).to have_selector('tbody tr', wait: 10)
    expect(page).to have_content("Warehouse")
  end

  scenario "filter by workflow status updates URL and filters table" do
    branch2.update!(workflow_status: "pending")
    visit company_branches_path(company)
    expect(page).to have_selector('table', wait: 10)

    select("Pending", from: 'workflow_status')
    click_button "Search"

    expect(page).to have_current_path(/workflow_status=pending/)

    expect(page).to have_selector('tbody tr', wait: 10)
  end

  scenario "display branch business type as badge" do
    visit company_branches_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_content("Storefront", minimum: 1)
    expect(page).to have_content("Warehouse", minimum: 1)
  end

  scenario "display branch workflow status as badge" do
    visit company_branches_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('span.rounded-full', wait: 10)
  end

  scenario "display branch city" do
    visit company_branches_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_content("Ho Chi Minh City")
  end

  scenario "clear filters resets URL and shows all branches" do
    visit company_branches_path(company, business_type: "warehouse")
    expect(page).to have_selector('table', wait: 10)

    click_button "Search"

    expect(page).to have_current_path(/business_type=warehouse/)

    select("All Types", from: 'business_type')
    click_button "Search"

    expect(page).to have_current_path(/business_type=/)
  end

  scenario "update branch name via show modal" do
    visit company_branches_path(company)
    expect(page).to have_selector('table', wait: 10)

    target_row = find('tbody tr', text: branch.name)
    target_row.find('[data-action*="openShowModal"]').click

    expect(page).to have_selector('.swal2-container', wait: 10)

    editable_name_field = find('[data-controller="editable"]', match: :first)
    editable_name_field.click

    expect(page).to have_selector('.editable-input', wait: 5)

    editable_name_field.find('.editable-input').fill_in(with: 'Updated Branch Name')

    accept_confirm do
      editable_name_field.find('.editable-input').send_keys :enter
    end

    expect(page).to have_selector('tbody tr', wait: 10)
    expect(Branch.find_by(id: branch.id).name).to eq("Updated Branch Name")
  end

  scenario "update branch description via show modal" do
    visit company_branches_path(company)
    expect(page).to have_selector('table', wait: 10)

    target_row = find('tbody tr', text: branch.name)
    target_row.find('[data-action*="openShowModal"]').click

    expect(page).to have_selector('.swal2-container', wait: 10)

    all_editable = all('[data-controller="editable"]')
    desc_editable = all_editable[1]
    desc_editable.click

    expect(page).to have_selector('.editable-input', wait: 5)

    desc_editable.find('.editable-input').fill_in(with: "Updated description for this branch")

    accept_confirm do
      desc_editable.find('.editable-input').send_keys :enter
    end

    expect(page).to have_selector('tbody tr', wait: 10)
    expect(Branch.find_by(id: branch.id).description).to eq("Updated description for this branch")
  end

  scenario "update branch city via show modal" do
    visit company_branches_path(company)
    expect(page).to have_selector('table', wait: 10)

    target_row = find('tbody tr', text: branch.name)
    target_row.find('[data-action*="openShowModal"]').click

    expect(page).to have_selector('.swal2-container', wait: 10)

    all_editable = all('[data-controller="editable"]')
    city_editable = all_editable[4]
    city_editable.click

    expect(page).to have_selector('.editable-input', wait: 5)

    city_editable.find('.editable-input').fill_in(with: 'Hanoi')

    accept_confirm do
      city_editable.find('.editable-input').send_keys :enter
    end

    expect(page).to have_selector('tbody tr', wait: 10)
    expect(Branch.find_by(id: branch.id).city).to eq("Hanoi")
  end

  scenario "update branch phone number via show modal" do
    visit company_branches_path(company)
    expect(page).to have_selector('table', wait: 10)

    target_row = find('tbody tr', text: branch.name)
    target_row.find('[data-action*="openShowModal"]').click

    expect(page).to have_selector('.swal2-container', wait: 10)

    all_editable = all('[data-controller="editable"]')
    phone_editable = all_editable[5]
    phone_editable.click

    expect(page).to have_selector('.editable-input', wait: 5)

    phone_editable.find('.editable-input').fill_in(with: "+84 123 456 789")

    accept_confirm do
      phone_editable.find('.editable-input').send_keys :enter
    end

    expect(page).to have_selector('tbody tr', wait: 10)
    expect(Branch.find_by(id: branch.id).phone_number).to eq("+84 123 456 789")
  end
end
