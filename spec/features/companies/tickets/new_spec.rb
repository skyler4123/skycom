require "rails_helper"

RSpec.feature "Companies::Tickets New", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

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

  scenario "renders new ticket form" do
    visit new_company_ticket_path(company)
    expect(page).to have_selector('input[name="ticket[name]"]', wait: 10)
  end

  scenario "creates ticket and redirects to show" do
    visit new_company_ticket_path(company)
    expect(page).to have_selector('input[name="ticket[name]"]', wait: 10)

    fill_in 'ticket[name]', with: 'Printer is broken'
    click_button "Save Ticket"

    expect(page).to have_content('Printer is broken', wait: 10)
    ticket = Ticket.find_by(name: "Printer is broken")
    expect(ticket).to be_present
    expect(page).to have_current_path(company_ticket_path(company, ticket), wait: 10)
  end
end