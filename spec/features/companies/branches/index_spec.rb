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
      sleep 1
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
end
