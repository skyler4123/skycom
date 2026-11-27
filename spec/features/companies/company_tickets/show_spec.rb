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
    cache_client_data(owner)
  end

  def cache_client_data(user)
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
      { user: JSON.parse(user.to_json), companies: [ company_data ], enums: {}, employees: [] }.to_json)
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

  scenario "lets the creator change visibility from the detail page" do
    visit company_company_ticket_path(company, ticket)
    expect(page).to have_content("VPN broken", wait: 10)
    expect(page).to have_select("company_ticket[visibility]", selected: "Only me", wait: 10)

    select "Everyone in company", from: "company_ticket[visibility]"
    click_button "Save"

    expect(page).to have_content("Visibility updated", wait: 10)
    expect(page).to have_content("Everyone", wait: 10)
    expect(page).to have_content("Visibility Changed", wait: 10)
    expect(page).to have_content("Only me → Everyone")
    expect(ticket.reload).to be_company_wide
  end

  scenario "shows a read-only visibility badge to a non-creator" do
    reader = grant_company_ticket_permissions(create(:employee, company: company), :read)
    shared = CompanyTicket.create!(company: company, employee: owner_employee,
      name: "Shared ticket", visibility: :company_wide)

    sign_in(reader.user)
    cache_client_data(reader.user)
    visit company_company_ticket_path(company, shared)

    expect(page).to have_content("Shared ticket", wait: 10)
    expect(page).to have_content("Everyone", wait: 10)
    expect(page).to have_content("Only the creator can change visibility.", wait: 10)
    expect(page).to have_no_select("company_ticket[visibility]")
  end

  scenario "shows not found for another employee's private ticket" do
    reader = grant_company_ticket_permissions(create(:employee, company: company), :read)
    other = create(:employee, company: company)
    hidden = CompanyTicket.create!(company: company, employee: other, name: "Hidden ticket")

    sign_in(reader.user)
    cache_client_data(reader.user)
    visit company_company_ticket_path(company, hidden)

    expect(page).to have_content("Ticket not found.", wait: 10)
    expect(page).not_to have_content("Hidden ticket")
  end

  scenario "clears an open ticket when it is made private" do
    reader = grant_company_ticket_permissions(create(:employee, company: company), :read)
    shared = CompanyTicket.create!(company: company, employee: owner_employee,
      name: "Shared soon private", visibility: :company_wide)

    sign_in(reader.user)
    cache_client_data(reader.user)
    visit company_company_ticket_path(company, shared)
    expect(page).to have_content("Shared soon private", wait: 10)

    shared.update!(visibility: :only_me)
    page.execute_script(
      "window.WEBSOCKET.handleIncomingPublication(Object.keys(window.WEBSOCKET.listeners)[0], " \
      "{ event: 'company_ticket_commented', id: arguments[0], payload: {} })",
      shared.id.to_s
    )

    expect(page).to have_content("Ticket not found.", wait: 10)
    expect(page).not_to have_content("Shared soon private")
  end
end
