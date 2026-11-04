# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::Operations index", type: :feature, js: true do
  let(:company) { create(:company, business_type: :retail) }
  let(:owner) { company.user }
  let!(:branch) { create(:branch, company: company, name: "Main Branch") }
  let!(:warehouse) { create(:warehouse, company: company, branch: branch, name: "Main Warehouse") }

  before do
    Seed::OperationService.seed_defaults!(company: company)
    sign_in(owner)
  end

  scenario "lists branch and warehouse appointments without an Add button" do
    visit company_operations_path(company)

    expect(page).to have_content("Operation Appointments", wait: 10)
    expect(page).to have_content("Appointments connect an operation to a branch or warehouse. Appointment configs override Operation configs.")
    expect(page).to have_content("POS")
    expect(page).to have_content("Main Branch")
    expect(page).to have_content("Inventory")
    expect(page).to have_content("Main Warehouse")
    expect(page).not_to have_link("Add")
  end

  scenario "filters operation appointments by type and location" do
    visit company_operations_path(company)

    expect(page).to have_select("operation_type", wait: 10)
    select "POS", from: "operation_type"
    select "#{branch.name} (Branch)", from: "location"
    click_button "Search"

    expect(page).to have_current_path(/operation_type=pos/, wait: 10)

    within("tbody") do
      expect(page).to have_content("POS")
      expect(page).not_to have_content("Booking")
      expect(page).not_to have_content("Main Warehouse")
    end
  end

  scenario "narrows local access roles for one appointment" do
    %w[Manager Cashier].each do |name|
      company.roles.find_by(name: name) || Seed::RoleService.create(company: company, name: name)
    end
    operation = company.operations.find_by!(operation_type: :pos)
    operation.update!(metadata: { "roles" => %w[Manager Cashier] })
    appointment = branch.branch_operation_appointments.find_by!(operation: operation)

    visit company_operations_path(company)

    within(find("tr", text: "POS", wait: 10)) { find("a[href$='/edit']").click }

    expect(page).to have_content("Local Access Roles", wait: 10)
    find("button[aria-haspopup='listbox']").click
    uncheck "Cashier"
    find("h2", text: "Appointment config").click
    click_button "Save"

    expect(page).to have_current_path(company_branch_operation_appointment_path(company, appointment), wait: 10)
    expect(page).to have_content("Manager", wait: 10)
    expect(page).not_to have_content("Cashier")
    expect(appointment.reload.metadata["roles"]).to eq([ "Manager" ])
  end

  scenario "opens the appointment show page from the operation name" do
    visit company_operations_path(company)

    within(find("tr", text: "POS", wait: 10)) { click_link "POS" }

    expect(page).to have_content(/Appointment config/i, wait: 10)
    expect(page).to have_content("Appointment config overrides Operation config. Company saves reset this local config.")
    expect(page).to have_content(/Effective Config/i)
    expect(page).to have_content("Main Branch")
    expect(page).to have_link("Edit Config")
  end

  scenario "edits appointment metadata and status on a full page" do
    visit company_operations_path(company)

    within(find("tr", text: "POS", wait: 10)) { find("a[href$='/edit']").click }

    expect(page).to have_content("Appointment config", wait: 10)
    find("textarea[name='metadata']").set('{"layout":{"columns":6}}')
    select "Inactive", from: "workflow_status"
    click_button "Save"

    expect(page).to have_content("Operation appointment updated.", wait: 10)
    expect(page).to have_content(/Appointment config/i, wait: 10)
    expect(page).to have_content("Inactive")
    expect(page).to have_content("columns")
  end

  scenario "edits a warehouse appointment on a full page" do
    visit company_operations_path(company)

    within(find("tr", text: "Inventory", wait: 10)) { find("a[href$='/edit']").click }

    expect(page).to have_content("Appointment config", wait: 10)
    expect(page).to have_content("Warehouse")
    find("textarea[name='metadata']").set('{"bin":"A1"}')
    click_button "Save"

    expect(page).to have_content("Operation appointment updated.", wait: 10)
    expect(page).to have_content(/Appointment config/i, wait: 10)
    expect(page).to have_content("Main Warehouse")
    expect(page).to have_content("bin")
  end

  scenario "launches the POS operation with the branch appointment" do
    visit company_operations_path(company)

    within(find("tr", text: "POS", wait: 10)) do
      find("a[href*='/launch']").click
    end

    expect(page).to have_current_path(%r{/companies/#{company.id}/operations/pos/}, wait: 10)
    expect(page).to have_content("Cart is empty", wait: 10)
  end

  scenario "shows a disabled launch when the employee lacks the operation role" do
    operation_record = company.operations.find_by!(operation_type: :pos)
    operation_record.update!(metadata: { "roles" => [ "Manager" ] })

    employee_user = create(:user, :company_employee)
    employee = create(:employee, company: company, branch: branch, user: employee_user)
    role = employee.attach_role("Cashier")
    policy = Policy.create!(
      company: company,
      name: "Operation read",
      resource: "Operation",
      action: "read",
      lifecycle_status: :active,
      workflow_status: :confirmed
    )
    PolicyRoleAppointment.create!(company: company, policy: policy, role: role, workflow_status: :active)

    sign_in(employee_user)
    visit company_operations_path(company)

    row = find("tr", text: "POS", wait: 10)
    expect(row).to have_content("You do not have access to this operation.")
    expect(row).not_to have_selector("a[href*='/launch']")
  end
end
