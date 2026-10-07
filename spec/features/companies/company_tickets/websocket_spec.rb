require "rails_helper"

RSpec.feature "Companies::CompanyTickets Live Updates", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:owner_employee) { company.employees.find_by(business_type: "owner") }
  let!(:ticket) do
    CompanyTicket.create!(company: company, employee: owner_employee,
      name: "VPN broken", description: "tunnel drops hourly", ticket_category: :technical)
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
    visit company_company_ticket_path(company, ticket)
    expect(page).to have_content("VPN broken", wait: 10)

    # Socket must be subscribed on the company channel.
    expect(page.evaluate_script("!!window.WEBSOCKET")).to be(true)
    expect(page.evaluate_script("Object.keys(window.WEBSOCKET.listeners).length")).to be >= 1

    message = "Live customer msg #{SecureRandom.hex(4)}"
    page.execute_script(
      "fetchJson(Helpers.company_company_ticket_comments_path(arguments[0]), " \
      "{ method: 'POST', body: { company_ticket_comment: " \
      "{ company_ticket_id: arguments[1], message: arguments[2] } } })",
      company.id.to_s, ticket.id.to_s, message
    )

    # No reload — the socket publication must trigger refresh().
    expect(page).to have_content(message, wait: 15)
  end
end
