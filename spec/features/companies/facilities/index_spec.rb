require "rails_helper"

RSpec.feature "Companies::Facilities Management", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company) }

  let!(:facility) { create(:facility, company: company, branch: branch) }

  before do
    sign_in(owner)
  end

  scenario "index page loads and displays facilities table" do
    visit company_facilities_path(company)

    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('th', text: 'Facility Name')
    expect(page).to have_selector('th', text: 'Category')
    expect(page).to have_selector('th', text: 'Branch')
    expect(page).to have_selector('th', text: 'Type')
    expect(page).to have_selector('th', text: 'Status')

    expect(page).to have_selector('tbody tr')
    expect(page).to have_content(facility.name)
  end

  scenario "create new facility via modal" do
    visit company_facilities_path(company)
    expect(page).to have_selector('table', wait: 10)

    find('[data-action*="openNewModal"]').click

    expect(page).to have_selector('form[data-action*="handleSubmit"]', wait: 10)

    fill_in 'facility[name]', with: 'New Test Facility'
    select branch.name, from: 'facility[branch_id]'
    select "Publicly traded", from: 'facility[business_type]'

    begin
      click_button "Save Facility"
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      visit company_facilities_path(company)
      expect(page).to have_selector('table', wait: 10)

      find('[data-action*="openNewModal"]').click

      expect(page).to have_selector('form[data-action*="handleSubmit"]', wait: 10)

      fill_in 'facility[name]', with: 'New Test Facility'
      select branch.name, from: 'facility[branch_id]'
      select "Publicly traded", from: 'facility[business_type]'
      click_button "Save Facility"
    end

    expect(page).to have_selector('tbody tr', wait: 10)
    expect(page).to have_content("New Test Facility")
  end

  scenario "filter by category updates URL and filters table" do
    category = Seed::CategoryService.create(company: company, name: "Test Category", resource_name: "facilities")
    facility.update!(category: category)
    visit company_facilities_path(company)
    expect(page).to have_selector('table', wait: 10)

    select(category.name, from: 'category_id')
    click_button "Search"

    expect(page).to have_current_path(/category_id=#{category.id}/)
    expect(page).to have_selector('tbody tr', wait: 10)
  end

  scenario "display facility workflow status as badge" do
    visit company_facilities_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('span.rounded-full', wait: 10)
  end
end
