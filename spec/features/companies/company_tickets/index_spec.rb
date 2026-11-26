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
    cache_client_data(owner)
  end

  def cache_client_data(user)
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
      { user: JSON.parse(user.to_json), companies: [ company_data ], enums: {}, employees: [] }.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "lists tickets with status, priority and open count" do
    visit company_company_tickets_path(company)

    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_content("Printer is down", wait: 10)
    expect(page).to have_content("Urgent")
    expect(page).to have_content("Open")
    expect(page).to have_content("Only me")
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

  scenario "shows the everyone badge on a company-wide ticket" do
    CompanyTicket.create!(company: company, employee: owner_employee,
      name: "Shared printer", visibility: :company_wide)

    visit company_company_tickets_path(company)

    expect(page).to have_content("Shared printer", wait: 10)
    expect(page).to have_content("Everyone", wait: 10)
  end

  scenario "hides another employee's private ticket from a reader" do
    reader = grant_company_ticket_permissions(create(:employee, company: company), :read)
    other = create(:employee, company: company)
    CompanyTicket.create!(company: company, employee: reader, name: "My private")
    CompanyTicket.create!(company: company, employee: other, name: "Other private")
    CompanyTicket.create!(company: company, employee: other, name: "Other shared",
      visibility: :company_wide)

    sign_in(reader.user)
    cache_client_data(reader.user)
    visit company_company_tickets_path(company)

    expect(page).to have_content("My private", wait: 10)
    expect(page).to have_content("Other shared", wait: 10)
    expect(page).not_to have_content("Other private")
    expect(page).not_to have_content("Printer is down")
  end

  scenario "lets the company owner see another employee's private ticket" do
    other = create(:employee, company: company)
    CompanyTicket.create!(company: company, employee: other, name: "Other private")

    visit company_company_tickets_path(company)

    expect(page).to have_content("Other private", wait: 10)
    expect(page).to have_content("Only me", wait: 10)
  end
end
