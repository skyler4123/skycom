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

    # Wait for the POST redirect to leave the form before reading the DB —
    # reading CompanyTicket.last in the matcher below races the request and
    # sees nil (FLAKY_TESTS §10).
    expect(page).to have_no_current_path(new_company_company_ticket_path(company), wait: 10)

    ticket = CompanyTicket.find_by!(name: "WiFi down in lobby")
    expect(page).to have_current_path(company_company_ticket_path(company, ticket), wait: 10)
    expect(page).to have_content("WiFi down in lobby", wait: 10)
    expect(ticket).to be_only_me
  end

  scenario "defaults to only me and explains who can see the ticket" do
    visit new_company_company_ticket_path(company)
    expect(page).to have_selector("form", wait: 10)

    expect(page).to have_checked_field("Only me")
    expect(page).to have_unchecked_field("Everyone in company")
    expect(page).to have_content("Only you, the company owner, and Skycom Support can see this ticket.")
    expect(page).to have_content("Skycom Support can always see every ticket.")
  end

  scenario "creates a company-wide ticket when everyone is selected" do
    visit new_company_company_ticket_path(company)
    expect(page).to have_selector("form", wait: 10)

    fill_in "company_ticket[name]", with: "Shared WiFi issue"
    select "Technical", from: "company_ticket[ticket_category]"
    choose "Everyone in company"
    click_button "Save Ticket"

    expect(page).to have_no_current_path(new_company_company_ticket_path(company), wait: 10)
    expect(CompanyTicket.find_by!(name: "Shared WiFi issue")).to be_company_wide
  end
end
