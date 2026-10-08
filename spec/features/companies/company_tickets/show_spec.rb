require "rails_helper"

RSpec.feature "Companies::CompanyTickets Show", type: :feature, js: true do
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

  def png_file
    file = Tempfile.new([ "shot", ".png" ])
    file.write("fake-png-bytes")
    file.rewind
    file
  end

  def xlsx_file
    file = Tempfile.new([ "report", ".xlsx" ])
    file.write("fake-xlsx-bytes")
    file.rewind
    file
  end

  scenario "posts a comment that appears in the thread" do
    visit company_company_ticket_path(company, ticket)
    expect(page).to have_content("VPN broken", wait: 10)

    fill_in "company_ticket_comment[message]", with: "Any update on this?"
    click_button "Post Comment"

    expect(page).to have_content("Any update on this?", wait: 10)
  end

  scenario "image attachment renders an image" do
    png = png_file

    visit company_company_ticket_path(company, ticket)
    expect(page).to have_content("VPN broken", wait: 10)

    fill_in "company_ticket_comment[message]", with: "Screen attached"
    attach_file "company_ticket_comment[file_attachments][]", png.path
    click_button "Post Comment"

    expect(page).to have_content("Screen attached", wait: 10)
    expect(page).to have_selector('img[src*="shot"]', wait: 10)
  end

  scenario "excel attachment renders an icon" do
    xlsx = xlsx_file

    visit company_company_ticket_path(company, ticket)
    expect(page).to have_content("VPN broken", wait: 10)

    fill_in "company_ticket_comment[message]", with: "Report attached"
    attach_file "company_ticket_comment[file_attachments][]", xlsx.path
    click_button "Post Comment"

    expect(page).to have_content("Report attached", wait: 10)
    expect(page).to have_content("report")
  end

  scenario "rates a resolved ticket" do
    ticket.transition_to!(:resolved, actor: owner_employee)

    visit company_company_ticket_path(company, ticket)
    expect(page).to have_content("VPN broken", wait: 10)

    select "5", from: "company_ticket[rate]"
    click_button "Rate"

    expect(page).to have_content("5 / 5", wait: 10)
  end

  scenario "open ticket shows no rating widget" do
    visit company_company_ticket_path(company, ticket)
    expect(page).to have_content("VPN broken", wait: 10)

    expect(page).not_to have_button("Rate")
  end

  scenario "renders user input as text, never as markup" do
    ticket.update!(name: '<img src=x onerror="window.__xss=1">')
    CompanyTicketComment.create_for!(ticket: ticket, author: owner_employee,
      message: '<script>window.__xss=2</script>')

    visit company_company_ticket_path(company, ticket)
    expect(page).to have_content("Back to Support Tickets", wait: 10)

    expect(page.evaluate_script("window.__xss")).to be_nil
  end
end
