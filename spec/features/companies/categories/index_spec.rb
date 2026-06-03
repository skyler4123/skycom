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

  # =========================================================================
  # Category Field Update Tests
  # =========================================================================

  scenario "updates category description via show modal" do
    visit company_categories_path(company)
    expect(page).to have_selector('table', wait: 10)

    target_row = find('tbody tr', text: category.name)
    target_row.find('[data-action*="openShowModal"]').click
    expect(page).to have_selector('.swal2-container', wait: 10)

    description_editable = all('[data-controller="editable"]')[2]
    description_editable.click

    expect(page).to have_selector('.editable-input', wait: 5)
    description_editable.find('.editable-input').fill_in(with: 'Updated Description')

    accept_confirm do
      description_editable.find('.editable-input').send_keys :enter
    end

    expect(page).to have_content("Description updated!", wait: 10)

    category.reload
    expect(category.description).to eq('Updated Description')
  end

  scenario "updates category resource name via show modal" do
    visit company_categories_path(company)
    expect(page).to have_selector('table', wait: 10)

    target_row = find('tbody tr', text: category.name)
    target_row.find('[data-action*="openShowModal"]').click
    expect(page).to have_selector('.swal2-container', wait: 10)

    resource_editable = all('[data-controller="editable"]')[1]
    resource_editable.click

    expect(page).to have_selector('.editable-input', wait: 5)
    resource_editable.find('.editable-input').fill_in(with: 'services')

    accept_confirm do
      resource_editable.find('.editable-input').send_keys :enter
    end

    expect(page).to have_content("Resource name updated!", wait: 10)

    category.reload
    expect(category.resource_name).to eq('services')
  end
end
