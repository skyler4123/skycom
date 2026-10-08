require "rails_helper"

RSpec.feature "Admin::CompanyTickets Pool", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner_employee) { company.employees.find_by(business_type: "owner") }
  let(:admin) { create(:user, :admin) }
  let!(:ticket) do
    CompanyTicket.create!(company: company, employee: owner_employee,
      name: "Printer is down", priority: :urgent)
  end

  before do
    sign_in(admin)
  end

  scenario "picks a ticket from the pool" do
    visit admin_company_tickets_path
    expect(page).to have_content("Printer is down", wait: 10)

    click_button "Pick Up"

    expect(page).to have_content(admin.email, wait: 10)
  end
end
