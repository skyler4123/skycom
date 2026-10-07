require "rails_helper"

RSpec.feature "Admin::CompanyTickets Live Updates", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner_employee) { company.employees.find_by(business_type: "owner") }
  let(:admin) { create(:user, :admin) }
  let!(:ticket) do
    CompanyTicket.create!(company: company, employee: owner_employee, name: "VPN broken")
  end

  before do
    sign_in(admin)
  end

  scenario "BE comment broadcast refreshes the open detail without clicking Refresh" do
    visit admin_company_ticket_path(ticket)
    expect(page).to have_content("VPN broken", wait: 10)

    # Socket must be subscribed — fails before the admin-layout token fix.
    expect(page.evaluate_script("!!window.WEBSOCKET")).to be(true)
    expect(page.evaluate_script("Object.keys(window.WEBSOCKET.listeners).length")).to be >= 1

    message = "Live staff reply #{SecureRandom.hex(4)}"
    page.execute_script(
      "fetchJson(Helpers.comment_admin_company_ticket_path(arguments[0]), " \
      "{ method: 'POST', body: { company_ticket_comment: { message: arguments[1] } } })",
      ticket.id.to_s, message
    )

    # No Refresh click — the socket publication must trigger refresh().
    expect(page).to have_content(message, wait: 15)
  end

  scenario "BE status broadcast refreshes the open detail without clicking Refresh" do
    visit admin_company_ticket_path(ticket)
    expect(page).to have_content("VPN broken", wait: 10)

    expect(page.evaluate_script("!!window.WEBSOCKET")).to be(true)

    page.execute_script(
      "fetchJson(Helpers.assign_admin_company_ticket_path(arguments[0]), { method: 'POST' })",
      ticket.id.to_s
    )

    # assign publishes company_ticket_status_changed -> refresh() shows assignee.
    expect(page).to have_content(admin.email, wait: 15)
  end
end
