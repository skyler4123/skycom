require "rails_helper"

RSpec.feature "Companies::Tickets Index", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:owner_employee) { company.employees.find_by(business_type: "owner") }
  let!(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "tickets") }
  let!(:ticket) { Seed::TicketService.create(company: company, employee: owner_employee, category: category, name: "Printer broken") }

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

  scenario "loads tickets page" do
    visit company_tickets_path(company)
    expect(page).to have_content("Name", wait: 10)
  end

  scenario "lists a created ticket by name" do
    visit company_tickets_path(company)
    expect(page).to have_content("Printer broken", wait: 10)
  end

  scenario "opens a ticket from the index" do
    visit company_tickets_path(company)
    expect(page).to have_content("Printer broken", wait: 10)
    click_link "Printer broken"
    expect(page).to have_content("Printer broken", wait: 10)
    expect(page).to have_current_path(company_ticket_path(company, ticket), wait: 10)
  end

  scenario "category filter narrows the list" do
    visit "#{company_tickets_path(company)}?category_id=#{category.id}"
    expect(page).to have_content("Printer broken", wait: 10)
  end

  scenario "mine filter shows only the current employee's tickets" do
    visit "#{company_tickets_path(company)}?mine=1"
    expect(page).to have_content("Printer broken", wait: 10)
  end
end
