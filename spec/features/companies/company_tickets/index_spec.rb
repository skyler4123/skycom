require "rails_helper"

RSpec.feature "Companies::CompanyTickets Index", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:owner_employee) { company.employees.find_by(business_type: "owner") }
  let!(:ticket) do
    CompanyTicket.create!(company: company, employee: owner_employee,
      name: "Printer is down", ticket_category: :technical, priority: :urgent)
  end

  before do
    sign_in(owner)

    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
      "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
      "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
      "branches" => [],
      "departments" => [],
      "roles" => []
    )

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])",
      { user: JSON.parse(owner.to_json), companies: [ company_data ], enums: {}, employees: [] }.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "lists tickets with status, priority and open count" do
    visit company_company_tickets_path(company)

    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_content("Printer is down", wait: 10)
    expect(page).to have_content("Urgent")
    expect(page).to have_content("Open")
  end

  scenario "filters by status" do
    visit company_company_tickets_path(company)
    expect(page).to have_content("Printer is down", wait: 10)

    select "Resolved", from: "status"
    click_button "Search"

    expect(page).to have_current_path(/status=resolved/, wait: 10)
    expect(page).not_to have_content("Printer is down")
  end

  scenario "shows Mine only filter and Raised by column" do
    visit company_company_tickets_path(company)
    expect(page).to have_content("Printer is down", wait: 10)

    expect(page).to have_unchecked_field("Mine only")
    expect(page).to have_content("Raised by")
  end

  scenario "filters to only the current employee tickets with Mine only" do
    other = create(:employee, company: company)
    CompanyTicket.create!(company: company, employee: other,
      name: "Other printer", ticket_category: :technical)

    visit company_company_tickets_path(company)
    expect(page).to have_content("Printer is down", wait: 10)
    expect(page).to have_content("Other printer", wait: 10)

    check "Mine only"
    click_button "Search"

    expect(page).to have_current_path(/mine=1/, wait: 10)
    expect(page).to have_content("Printer is down", wait: 10)
    expect(page).not_to have_content("Other printer")
  end
end
