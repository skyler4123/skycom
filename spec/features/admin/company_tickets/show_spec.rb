require "rails_helper"

RSpec.feature "Admin::CompanyTickets Detail", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner_employee) { company.employees.find_by(business_type: "owner") }
  let(:admin) { create(:user, :admin) }
  let!(:ticket) do
    CompanyTicket.create!(company: company, employee: owner_employee, name: "VPN broken")
  end

  before do
    sign_in(admin)
  end

  scenario "comments and resolves the ticket" do
    visit admin_company_ticket_path(ticket)
    expect(page).to have_content("VPN broken", wait: 10)

    click_button "Pick Up"
    expect(page).to have_content(admin.email, wait: 10)

    fill_in "company_ticket_comment[message]", with: "Fixed in v2"
    click_button "Post Comment"
    expect(page).to have_content("Fixed in v2", wait: 10)

    click_button "Resolve"
    expect(page).to have_content("Resolved", wait: 10)
  end

  scenario "refresh button re-renders the detail" do
    visit admin_company_ticket_path(ticket)
    expect(page).to have_content("VPN broken", wait: 10)

    click_button "Refresh"
    expect(page).to have_content("VPN broken", wait: 10)
  end
end
