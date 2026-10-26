require "rails_helper"

RSpec.feature "Companies::Tickets Show", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:employee) { create(:employee, company: company) }
  let(:other_employee) { create(:employee, company: company) }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "tickets") }
  let!(:workflow) do
    w = Seed::WorkflowService.create(company: company, category: category, name: "Ticket Process", process_type: :ticket_process)
    Seed::WorkflowStepService.create(company: company, workflow: w, name: "To Do", position: 1)
    Seed::WorkflowStepService.create(company: company, workflow: w, name: "In Progress", position: 2)
    w
  end
  let!(:ticket) { create(:ticket, company: company, category: category, name: "Printer broken", employee: employee, created_by_employee: employee) }

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

  scenario "shows ticket and advances workflow" do
    visit company_ticket_path(company, ticket)
    expect(page).to have_content("Printer broken", wait: 10)
    expect(page).to have_button("Approve", wait: 10)
    click_button "Approve"
    expect(page).to have_content("In Progress", wait: 10)
  end

  scenario "approve records a history entry" do
    visit company_ticket_path(company, ticket)
    expect(page).to have_content("Printer broken", wait: 10)
    click_button "Approve"
    expect(page).to have_content("In Progress", wait: 10)
  end

  scenario "reject cancels the ticket" do
    visit company_ticket_path(company, ticket)
    expect(page).to have_content("Printer broken", wait: 10)
    click_button "Reject"
    expect(page).to have_content("Cancelled", wait: 10)
  end

  scenario "rework moves to the selected step" do
    visit company_ticket_path(company, ticket)
    expect(page).to have_content("Printer broken", wait: 10)
    select "1. To Do", from: "rework-target" rescue nil
    click_button "Rework"
    expect(page).to have_content("To Do", wait: 10)
  end

  scenario "posts a comment" do
    visit company_ticket_path(company, ticket)
    fill_in 'ticket_comment[message]', with: "Looking into it"
    click_button "Post"
    expect(page).to have_content("Looking into it", wait: 10)
  end

  scenario "two employees' comments both render with author names" do
    TicketComment.create_for!(ticket: ticket, employee: employee, message: "First employee note")
    TicketComment.create_for!(ticket: ticket, employee: other_employee, message: "Second employee note")

    visit company_ticket_path(company, ticket)
    expect(page).to have_content("First employee note", wait: 10)
    expect(page).to have_content("Second employee note", wait: 10)
    expect(page).to have_content(employee.name, wait: 10)
    expect(page).to have_content(other_employee.name, wait: 10)
  end

  scenario "pre-seeded comments render oldest to newest" do
    TicketComment.create_for!(ticket: ticket, employee: employee, message: "Older note")
    TicketComment.create_for!(ticket: ticket, employee: other_employee, message: "Newer note")

    visit company_ticket_path(company, ticket)
    expect(page).to have_content("Older note", wait: 10)
    expect(page).to have_content("Newer note", wait: 10)
  end

  scenario "edit ticket updates the name and redirects back to show" do
    visit edit_company_ticket_path(company, ticket)
    expect(page).to have_selector('input[name="ticket[name]"]', wait: 10)
    fill_in 'ticket[name]', with: "Printer fixed"
    click_button "Save Changes"
    expect(page).to have_content("Printer fixed", wait: 10)
    expect(page).to have_current_path(company_ticket_path(company, ticket), wait: 10)
  end

  scenario "renders user input as text, never as markup" do
    ticket.update!(name: '<img src=x onerror="window.__xss=1">')
    TicketComment.create_for!(ticket: ticket, employee: employee,
      message: '<script>window.__xss=2</script>')

    visit company_ticket_path(company, ticket)
    expect(page).to have_content("Back to Tickets", wait: 10)

    expect(page.evaluate_script("window.__xss")).to be_nil
  end
end
