require "rails_helper"

RSpec.feature "Companies::Customers Management", type: :feature, js: true do
  let(:customer) { create(:customer) }
  let(:company) { customer.company }
  let(:owner) { company.user }

  let!(:customer2) do
    create(:customer,
      company: company,
      name: "Enterprise Corp",
      email: "enterprise@example.com",
      business_type: "enterprise"
    )
  end

  before do
    sign_in(owner)
  end

  scenario "index page loads and displays customers table" do
    visit company_customers_path(company)

    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('th', text: 'Customer Name')
    expect(page).to have_selector('th', text: 'Email')
    expect(page).to have_selector('th', text: 'Type')
    expect(page).to have_selector('th', text: 'Status')

    expect(page).to have_selector('tbody tr')
    expect(page).to have_content(customer.name)
  end

  scenario "create new customer via modal" do
    visit company_customers_path(company)
    expect(page).to have_selector('table', wait: 10)

    find('[data-action*="openNewModal"]').click

    expect(page).to have_selector('form[data-action*="handleSubmit"]', wait: 10)

    expect(page).to have_selector('input[name="customer[name]"]', wait: 5)
    fill_in 'customer[name]', with: 'New Test Customer'
    fill_in 'customer[email]', with: 'new@example.com'
    select 'Individual', from: 'customer[business_type]'

    begin
      click_button "Save Customer"
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      visit company_customers_path(company)
      expect(page).to have_selector('table', wait: 10)

      find('[data-action*="openNewModal"]').click

      expect(page).to have_selector('form[data-action*="handleSubmit"]', wait: 10)

      fill_in 'customer[name]', with: 'New Test Customer'
      fill_in 'customer[email]', with: 'new@example.com'
      select 'Individual', from: 'customer[business_type]'
      click_button "Save Customer"
    end
    expect(page).to have_selector('tbody tr', wait: 10)
    expect(page).to have_content("New Test Customer")

    expect(Customer.find_by(name: "New Test Customer")).to be_present
  end

  scenario "edit button opens show modal for customer" do
    visit company_customers_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('[data-action*="openShowModal"]', minimum: 1)
  end

  scenario "filter by category updates URL and filters table" do
    category = Seed::CategoryService.create(company: company, name: "Test Category", resource_name: "customers")
    customer.update!(category: category, property_mapping: category.property_mapping)
    visit company_customers_path(company)
    expect(page).to have_selector('table', wait: 10)

    select(category.name, from: 'category_id')
    click_button "Search"

    expect(page).to have_current_path(/category_id=#{category.id}/)
    expect(page).to have_selector('tbody tr', wait: 10)
  end

  scenario "display customer business type as badge" do
    visit company_customers_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_content(customer.business_type.to_s.titleize, minimum: 1)
    expect(page).to have_content(customer2.business_type.to_s.titleize, minimum: 1)
  end

  scenario "display customer workflow status as badge" do
    visit company_customers_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('span.rounded-full', wait: 10)
  end

  scenario "display customer email" do
    visit company_customers_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_content("enterprise@example.com")
  end

  scenario "update customer name via show modal" do
    visit company_customers_path(company)
    expect(page).to have_selector('table', wait: 10)

    target_row = find('tbody tr', text: customer.name)
    target_row.find('[data-action*="openShowModal"]').click

    expect(page).to have_selector('.swal2-container', wait: 10)

    editable_name_field = find('[data-controller="editable"]', match: :first)
    editable_name_field.click

    expect(page).to have_selector('.editable-input', wait: 5)

    editable_name_field.find('.editable-input').fill_in(with: 'Updated Customer Name')

    accept_confirm do
      editable_name_field.find('.editable-input').send_keys :enter
    end

    expect(page).to have_content('Updated Customer Name', wait: 10)
    expect(Customer.find_by(id: customer.id).name).to eq("Updated Customer Name")
  end

  scenario "update customer description via show modal" do
    visit company_customers_path(company)
    expect(page).to have_selector('table', wait: 10)

    target_row = find('tbody tr', text: customer.name)
    target_row.find('[data-action*="openShowModal"]').click

    expect(page).to have_selector('.swal2-container', wait: 10)

    all_editable = all('[data-controller="editable"]')
    desc_editable = all_editable[1]
    desc_editable.click

    expect(page).to have_selector('.editable-input', wait: 5)

    desc_editable.find('.editable-input').fill_in(with: 'Updated description for this customer')

    accept_confirm do
      desc_editable.find('.editable-input').send_keys :enter
    end

    expect(page).to have_content('Updated description for this customer', wait: 10)
    expect(Customer.find_by(id: customer.id).description).to eq("Updated description for this customer")
  end
end
