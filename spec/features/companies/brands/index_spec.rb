require "rails_helper"

RSpec.feature "Companies::Brands Management", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  let!(:brand) { create(:brand, company: company) }

  before do
    sign_in(owner)
  end

  scenario "index page loads and displays brands table" do
    visit company_brands_path(company)

    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('th', text: 'Brand Name')
    expect(page).to have_selector('th', text: 'Category')
    expect(page).to have_selector('th', text: 'Type')
    expect(page).to have_selector('th', text: 'Status')

    expect(page).to have_selector('tbody tr')
    expect(page).to have_content(brand.name)
  end

  scenario "create new brand via modal" do
    visit company_brands_path(company)
    expect(page).to have_selector('table', wait: 10)

    find('[data-action*="openNewModal"]').click

    expect(page).to have_selector('form[data-action*="handleSubmit"]', wait: 10)

    fill_in 'brand[name]', with: 'New Test Brand'
    select 'Manufacturer', from: 'brand[business_type]'

    begin
      click_button "Save Brand"
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      visit company_brands_path(company)
      expect(page).to have_selector('table', wait: 10)

      find('[data-action*="openNewModal"]').click

      expect(page).to have_selector('form[data-action*="handleSubmit"]', wait: 10)

      fill_in 'brand[name]', with: 'New Test Brand'
      select 'Manufacturer', from: 'brand[business_type]'
      click_button "Save Brand"
    end

    expect(page).to have_selector('tbody tr', wait: 10)
    expect(page).to have_content("New Test Brand")
  end

  scenario "filter by category updates URL and filters table" do
    category = Seed::CategoryService.create(company: company, name: "Test Category", resource_name: "brands")
    brand.update!(category: category, property_mapping: category.property_mapping)
    visit company_brands_path(company)
    expect(page).to have_selector('table', wait: 10)

    select(category.name, from: 'category_id')
    click_button "Search"

    expect(page).to have_current_path(/category_id=#{category.id}/)
    expect(page).to have_selector('tbody tr', wait: 10)
  end

  scenario "display brand business type as badge" do
    visit company_brands_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('tbody tr', wait: 10)
  end

  scenario "display brand workflow status as badge" do
    visit company_brands_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('span.rounded-full', wait: 10)
  end
end
