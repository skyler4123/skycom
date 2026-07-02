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

  scenario "edit button links to edit page for category" do
    visit company_categories_path(company)
    expect(page).to have_selector('table', wait: 10)

    edit_link = find("a[href*='/edit']", match: :first)
    expect(edit_link).to be_present
  end

  scenario "name link goes to show page" do
    visit company_categories_path(company)
    expect(page).to have_selector('table', wait: 10)

    find("a[href*='/categories/#{category.id}']", text: category.name, match: :first).click
    expect(page).to have_current_path(/categories\/#{category.id}$/, wait: 10)
    expect(page).to have_content(category.name)
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

  scenario "search triggers form submission and displays results" do
    visit company_categories_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_button("Search")

    click_button "Search"

    expect(page).to have_selector('tbody tr', wait: 10)
  end

  scenario "show page displays category details" do
    visit company_category_path(company, category)
    expect(page).to have_content(category.name, wait: 10)

    expect(page).to have_content(category.resource_name)
    expect(page).to have_content("Property Fields")
  end
end
