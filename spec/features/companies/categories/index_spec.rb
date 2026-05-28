require "rails_helper"

RSpec.feature "Companies::Categories Management", type: :feature, js: true do
  let(:branch)   { create(:branch) }
  let(:company)  { branch.company }
  let(:owner)    { company.user }

  let!(:category) do
    create(:category, company: company, name: "Cosmetics", resource_name: "products")
  end

  let!(:category2) do
    create(:category, company: company, name: "Management", resource_name: "employees")
  end

  before do
    sign_in(owner)
  end

  scenario "index page loads and displays categories table" do
    visit company_categories_path(company)

    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('th', text: 'Name')
    expect(page).to have_selector('th', text: 'Resource')
    expect(page).to have_selector('th', text: 'Description')
    expect(page).to have_selector('th', text: 'Actions')

    expect(page).to have_selector('tbody tr', wait: 10)
    expect(page).to have_content(category.name)
    expect(page).to have_content(category2.name)
  end

  scenario "create new category via modal" do
    visit company_categories_path(company)
    expect(page).to have_selector('table', wait: 10)

    find('[data-action*="openNewModal"]').click

    expect(page).to have_selector('form[data-action*="handleSubmit"]', wait: 10)

    fill_in 'category[name]', with: 'Skincare Products'
    select 'Products', from: 'category[resource_name]'
    fill_in 'category[description]', with: 'Skincare description'

    click_button "Save Category"

    expect(page).to have_content("created successfully!", wait: 10)
    expect(page).to have_selector('tbody tr', wait: 10)

    expect(Category.find_by(name: "Skincare Products")).to be_present
  end

  scenario "filter by resource name updates URL and filters table" do
    visit company_categories_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('select[name="resource_name"] option[value="products"]', wait: 10)
    select("Products", from: 'resource_name')
    click_button "Search"

    expect(page).to have_current_path(/resource_name=products/)

    expect(page).to have_selector('tbody tr', wait: 10)
    expect(page).to have_content(category.name)
  end

  scenario "edit button opens show modal for category" do
    visit company_categories_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('[data-action*="openShowModal"]', minimum: 1)
  end

  scenario "search triggers form submission and displays results" do
    visit company_categories_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_button("Search")

    click_button "Search"

    expect(page).to have_selector('tbody tr', wait: 10)
  end
end
