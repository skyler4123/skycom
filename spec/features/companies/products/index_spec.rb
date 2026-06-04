require "rails_helper"

RSpec.feature "Companies::Products Management", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }

  let!(:product) do
    create(:product,
      company: company,
      business_type: "physical"
    )
  end

  let!(:product2) do
    create(:product,
      company: company,
      business_type: "digital",
      workflow_status: "pending"
    )
  end

  before do
    sign_in(owner)
  end

  scenario "index page loads and displays products table" do
    visit company_products_path(company)

    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('th', text: 'Product Name')
    expect(page).to have_selector('th', text: 'Type')
    expect(page).to have_selector('th', text: 'Status')

    expect(page).to have_selector('tbody tr')
    expect(page).to have_content(product.name)
  end

  scenario "create new product via modal" do
    visit company_products_path(company)
    expect(page).to have_selector('table', wait: 10)

    find('[data-action*="openNewModal"]').click

    expect(page).to have_selector('form[data-action*="handleSubmit"]', wait: 10)

    expect(page).to have_selector('input[name="product[name]"]', wait: 5)
    fill_in 'product[name]', with: 'New Test Product'
    select 'Digital', from: 'product[business_type]'

    click_button "Save Product"

    expect(page).to have_content("created successfully", wait: 10)
    expect(page).to have_selector('tbody tr', wait: 10)

    expect(Product.find_by(name: "New Test Product")).to be_present
  end

  scenario "edit button opens show modal for product" do
    visit company_products_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('[data-action*="openShowModal"]', minimum: 1)
  end

  scenario "filter by category updates URL and filters table" do
    category = Seed::CategoryService.create(company: company, name: "Test Category", resource_name: "products")
    product.update!(category: category, property_mapping: category.property_mapping)
    visit company_products_path(company)
    expect(page).to have_selector('table', wait: 10)

    select(category.name, from: 'category_id')
    click_button "Search"

    expect(page).to have_current_path(/category_id=#{category.id}/)
    expect(page).to have_selector('tbody tr', wait: 10)
  end

  scenario "display product business type as badge" do
    visit company_products_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_content("Physical", minimum: 1)
    expect(page).to have_content("Digital", minimum: 1)
  end

  scenario "display product workflow status as badge" do
    visit company_products_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('span.rounded-full', wait: 10)
  end

  scenario "update product name via show modal" do
    visit company_products_path(company)
    expect(page).to have_selector('table', wait: 10)

    target_row = find('tbody tr', text: product.name)
    target_row.find('[data-action*="openShowModal"]').click

    expect(page).to have_selector('.swal2-container', wait: 10)

    editable_name_field = find('[data-controller="editable"]', match: :first)
    editable_name_field.click

    expect(page).to have_selector('.editable-input', wait: 5)

    editable_name_field.find('.editable-input').fill_in(with: 'Updated Product Name')

    accept_confirm do
      editable_name_field.find('.editable-input').send_keys :enter
    end

    expect(page).to have_content('Updated Product Name', wait: 10)
    expect(Product.find_by(id: product.id).name).to eq("Updated Product Name")
  end

  scenario "update product description via show modal" do
    visit company_products_path(company)
    expect(page).to have_selector('table', wait: 10)

    target_row = find('tbody tr', text: product.name)
    target_row.find('[data-action*="openShowModal"]').click

    expect(page).to have_selector('.swal2-container', wait: 10)

    all_editable = all('[data-controller="editable"]')
    desc_editable = all_editable[1]
    desc_editable.click

    expect(page).to have_selector('.editable-input', wait: 5)

    desc_editable.find('.editable-input').fill_in(with: 'Updated description for this product')

    accept_confirm do
      desc_editable.find('.editable-input').send_keys :enter
    end

    expect(page).to have_content('Updated description for this product', wait: 10)
    expect(Product.find_by(id: product.id).description).to eq("Updated description for this product")
  end
end
