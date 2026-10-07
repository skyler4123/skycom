require "rails_helper"

RSpec.feature "Companies::CompanyTickets New", type: :feature, js: true do
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

  scenario "creates a ticket and lands on its page" do
    visit new_company_company_ticket_path(company)
    expect(page).to have_selector("form", wait: 10)

    fill_in "company_ticket[name]", with: "WiFi down in lobby"
    fill_in "company_ticket[description]", with: "No signal since morning"
    select "Technical", from: "company_ticket[ticket_category]"
    select "High", from: "company_ticket[priority]"
    click_button "Save Ticket"

    expect(page).to have_current_path(company_company_ticket_path(company, CompanyTicket.last), wait: 10)
    expect(page).to have_content("WiFi down in lobby", wait: 10)
  end
end
