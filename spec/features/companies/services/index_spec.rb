require "rails_helper"

RSpec.feature "Companies::Services Management", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }

  let!(:service) do
    Seed::ServiceService.create(
      company: company,
      branch: branch,
      name: "Test Service 1",
      business_type: "b2b",
      workflow_status: "draft"
    )
  end

  let!(:service2) do
    Seed::ServiceService.create(
      company: company,
      branch: branch,
      name: "Test Service 2",
      business_type: "b2c",
      workflow_status: "pending"
    )
  end

  before do
    sign_in(owner)
  end

  scenario "index page loads and displays services table" do
    visit company_services_path(company)

    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('th', text: 'Service Name')
    expect(page).to have_selector('th', text: 'Type')
    expect(page).to have_selector('th', text: 'Status')

    expect(page).to have_selector('tbody tr')
    expect(page).to have_content(service.name)
  end

  scenario "create new service via modal" do
    visit company_services_path(company)
    expect(page).to have_selector('table', wait: 10)

    find('[data-action*="openNewModal"]').click

    expect(page).to have_selector('form[data-action*="handleSubmit"]', wait: 10)

    expect(page).to have_selector('input[name="service[name]"]', wait: 5)
    fill_in 'service[name]', with: 'New Test Service'
    select 'B2C', from: 'service[business_type]'

    click_button "Save Service"

    expect(page).to have_content("created successfully", wait: 10)
    expect(page).to have_selector('tbody tr', wait: 10)

    expect(Service.find_by(name: "New Test Service")).to be_present
  end

  scenario "edit button opens show modal for service" do
    visit company_services_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('[data-action*="openShowModal"]', minimum: 1)
  end

  scenario "search triggers form submission and filters results" do
    visit company_services_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_button("Search")

    click_button "Search"

    expect(page).to have_selector('tbody tr', wait: 10)
  end



  scenario "filter by category updates URL and filters table" do
    category = Seed::CategoryService.create(company: company, name: "Test Category", resource_name: "services")
    service.update!(category: category)
    visit company_services_path(company)
    expect(page).to have_selector('table', wait: 10)

    select(category.name, from: 'category_id')
    click_button "Search"

    expect(page).to have_current_path(/category_id=#{category.id}/)
    expect(page).to have_selector('tbody tr', wait: 10)
  end

  scenario "filter by workflow status updates URL and filters table" do
    service2.update!(workflow_status: :pending)
    visit company_services_path(company)
    expect(page).to have_selector('table', wait: 10)

    select("Pending", from: 'workflow_status')
    click_button "Search"

    expect(page).to have_current_path(/workflow_status=pending/)

    expect(page).to have_selector('tbody tr', wait: 10)
  end

  scenario "display service business type as badge" do
    visit company_services_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_content("B2B", minimum: 1)
    expect(page).to have_content("B2C", minimum: 1)
  end

  scenario "display service workflow status as badge" do
    visit company_services_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('span.rounded-full', wait: 10)
  end

  scenario "clear filters resets URL and shows all services" do
    visit company_services_path(company, business_type: "b2c")
    expect(page).to have_selector('table', wait: 10)

    click_button "Search"

    expect(page).to have_current_path(/business_type=b2c/)

    select("All Types", from: 'business_type')
    click_button "Search"

    expect(page).to have_current_path(/business_type=/)
  end

  scenario "update service name via show modal" do
    visit company_services_path(company)
    expect(page).to have_selector('table', wait: 10)

    target_row = find('tbody tr', text: service.name)
    target_row.find('[data-action*="openShowModal"]').click

    expect(page).to have_selector('.swal2-container', wait: 10)

    editable_name_field = find('[data-controller="editable"]', match: :first)
    editable_name_field.click

    expect(page).to have_selector('.editable-input', wait: 5)

    editable_name_field.find('.editable-input').fill_in(with: 'Updated Service Name')

    accept_confirm do
      editable_name_field.find('.editable-input').send_keys :enter
    end

    expect(page).to have_selector('tbody tr', wait: 10)
    expect(Service.find_by(id: service.id).name).to eq("Updated Service Name")
  end

  scenario "update service description via show modal" do
    visit company_services_path(company)
    expect(page).to have_selector('table', wait: 10)

    target_row = find('tbody tr', text: service.name)
    target_row.find('[data-action*="openShowModal"]').click

    expect(page).to have_selector('.swal2-container', wait: 10)

    all_editable = all('[data-controller="editable"]')
    desc_editable = all_editable[1]
    desc_editable.click

    expect(page).to have_selector('.editable-input', wait: 5)

    desc_editable.find('.editable-input').fill_in(with: 'Updated description for this service')

    accept_confirm do
      desc_editable.find('.editable-input').send_keys :enter
    end

    expect(page).to have_selector('tbody tr', wait: 10)
    expect(Service.find_by(id: service.id).description).to eq("Updated description for this service")
  end
end
