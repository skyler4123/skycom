require "rails_helper"

RSpec.feature "Companies::Tickets Permissions", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:owner_employee) { company.employees.find_by(business_type: "owner") }

  let!(:reader_role) { create(:role, company: company, name: "Reader", business_type: :support) }

  let!(:policy_read_ticket) do
    Seed::PolicyService.create(
      company: company,
      name: "Can read Ticket",
      resource: "Ticket",
      action: "read",
      business_type: :operational,
      lifecycle_status: :active
    )
  end

  let!(:reader_read_ticket_active) do
    PolicyRoleAppointment.find_or_create_by!(
      company: company,
      policy: policy_read_ticket,
      role: reader_role
    ).tap { |a| a.update!(workflow_status: :active) }
  end

  let(:reader_user) { create(:user, :company_employee) }
  let!(:reader_employee) do
    emp = create(:employee, company: company, user: reader_user)
    create(:employee_role_appointment, company: company, employee: emp, role: reader_role)
    emp
  end

  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "tickets") }
  let!(:workflow) do
    w = Seed::WorkflowService.create(company: company, category: category, name: "Ticket Process", process_type: :ticket_process)
    Seed::WorkflowStepService.create(company: company, workflow: w, name: "To Do", position: 1)
    Seed::WorkflowStepService.create(company: company, workflow: w, name: "In Progress", position: 2)
    w
  end
  let!(:ticket) { Seed::TicketService.create(company: company, employee: owner_employee, category: category, name: "Permission ticket") }

  before do
    company.clear_permissions_cache
    reader_employee.clear_permissions_cache
    reader_employee.reload
    sign_in(reader_user)
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
      { user: JSON.parse(reader_user.to_json), companies: [ company_data ], enums: {}, employees: [] }.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "employee without update permission cannot advance the ticket" do
    visit company_ticket_path(company, ticket)
    expect(page).to have_content("Permission ticket", wait: 10)
    expect(page).to have_button("Approve", wait: 10)
    click_button "Approve"
    expect(page).to have_content("To Do", wait: 10)
  end
end
