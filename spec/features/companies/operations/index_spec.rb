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

  scenario "lists operations for branches and warehouses without an Add button" do
    visit company_operations_path(company)

    expect(page).to have_selector("h2", exact_text: "Operations", wait: 10)
    expect(page).to have_content("Each operation is available at your branches and warehouses. Launch it, or edit the settings for that location.")
    expect(page).to have_content("POS")
    expect(page).to have_content("Main Branch")
    expect(page).to have_content("Inventory")
    expect(page).to have_content("Main Warehouse")
    expect(page).not_to have_link("Add")
  end

  scenario "filters operations by type and location" do
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

  scenario "narrows access roles for one location" do
    %w[Manager Cashier].each do |name|
      company.roles.find_by(name: name) || Seed::RoleService.create(company: company, name: name)
    end
    operation = company.operations.find_by!(operation_type: :pos)
    operation.update!(metadata: { "roles" => %w[Manager Cashier] })
    appointment = branch.branch_operation_appointments.find_by!(operation: operation)

    visit company_operations_path(company)

    within(find("tr", text: "POS", wait: 10)) { find("a[href$='/edit']").click }

    expect(page).to have_content("Access Roles", wait: 10)
    expect(page).not_to have_content(/Local Access Roles/i)
    find("button[aria-haspopup='listbox']").click
    uncheck "Cashier"
    find("h2", exact_text: "Operation").click
    click_button "Save"

    expect(page).to have_current_path(company_branch_operation_appointment_path(company, appointment), wait: 10)
    expect(page).to have_content("Manager", wait: 10)
    expect(page).not_to have_content("Cashier")
    expect(appointment.reload.metadata["roles"]).to eq([ "Manager" ])
  end

  scenario "opens the operation show page from the operation name" do
    visit company_operations_path(company)

    within(find("tr", text: "POS", wait: 10)) { click_link "POS" }

    expect(page).to have_content(/Operation · Branch/i, wait: 10)
    expect(page).to have_content("Settings here apply to this location. Saving the Operation config resets them.")
    expect(page).not_to have_content(/Metadata \(JSON\)/i)
    expect(page).not_to have_content(/Effective Config/i)
    expect(page).to have_content("Main Branch")
    expect(page).to have_link("Edit Config")
  end

  scenario "edits status without exposing metadata JSON" do
    operation = company.operations.find_by!(operation_type: :pos)
    appointment = branch.branch_operation_appointments.find_by!(operation: operation)
    appointment.update!(metadata: appointment.metadata.merge("layout" => { "columns" => 6 }))

    visit company_operations_path(company)

    within(find("tr", text: "POS", wait: 10)) { find("a[href$='/edit']").click }

    find("h2", exact_text: "Operation", wait: 10)
    expect(page).not_to have_content(/Other metadata \(JSON\)/i)
    expect(page).not_to have_selector("textarea[name='metadata']")
    select "Inactive", from: "workflow_status"
    click_button "Save"

    expect(page).to have_current_path(company_branch_operation_appointment_path(company, appointment), wait: 10)
    expect(page).to have_content("Operation updated.", wait: 10)
    expect(page).to have_content("Inactive")
    expect(appointment.reload.metadata["layout"]).to eq({ "columns" => 6 })
  end

  scenario "edits a warehouse operation status and preserves hidden metadata" do
    operation = company.operations.find_by!(operation_type: :inventory)
    appointment = warehouse.operation_warehouse_appointments.find_by!(operation: operation)
    appointment.update!(metadata: appointment.metadata.merge("bin" => "A1"))

    visit company_operations_path(company)

    within(find("tr", text: "Inventory", wait: 10)) { find("a[href$='/edit']").click }

    find("h2", exact_text: "Operation", wait: 10)
    expect(page).to have_content("Warehouse")
    expect(page).not_to have_selector("textarea[name='metadata']")
    select "Inactive", from: "workflow_status"
    click_button "Save"

    expect(page).to have_current_path(company_operation_warehouse_appointment_path(company, appointment), wait: 10)
    expect(page).to have_content("Operation updated.", wait: 10)
    expect(page).to have_content("Inactive")
    expect(appointment.reload.metadata["bin"]).to eq("A1")
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
