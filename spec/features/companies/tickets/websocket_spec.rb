require "rails_helper"

RSpec.feature "Companies::Tickets Live Updates", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:owner_employee) { company.employees.find_by(business_type: "owner") }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "tickets") }
  let!(:ticket) do
    Seed::TicketService.create(company: company, employee: owner_employee, category: category, name: "Printer broken")
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

  scenario "BE comment broadcast refreshes the open detail without manual reload" do
    visit company_ticket_path(company, ticket)
    expect(page).to have_content("Printer broken", wait: 10)

    expect(page.evaluate_script("!!window.WEBSOCKET")).to be(true)
    expect(page.evaluate_script("Object.keys(window.WEBSOCKET.listeners).length")).to be >= 1

    message = "Live ticket msg #{SecureRandom.hex(4)}"
    page.execute_script(
      "fetchJson(Helpers.company_ticket_comments_path(arguments[0]), " \
      "{ method: 'POST', body: { ticket_comment: " \
      "{ ticket_id: arguments[1], message: arguments[2] } } })",
      company.id.to_s, ticket.id.to_s, message
    )

    expect(page).to have_content(message, wait: 15)
  end

  scenario "comment events for other tickets are ignored on the open detail" do
    other = Seed::TicketService.create(company: company, employee: owner_employee, category: category, name: "Other ticket")
    visit company_ticket_path(company, ticket)
    expect(page).to have_content("Printer broken", wait: 10)

    page.execute_script(
      "window.WEBSOCKET.handleIncomingPublication(" \
      "Object.keys(window.WEBSOCKET.listeners)[0], " \
      "{ event: 'ticket_commented', id: arguments[0], " \
      "payload: { comment: { id: 'ghost', message: 'Ghost msg', employee_name: 'Ghost', created_at: new Date().toISOString() } } })",
      other.id.to_s
    )

    expect(page).not_to have_content("Ghost msg")
    expect(page).not_to have_content("Ghost", wait: 3)
  end
end