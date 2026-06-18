require "rails_helper"

RSpec.feature "Companies::Invoices Permissions", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  let!(:default_category) do
    Seed::CategoryService.find_or_create_for(company: company, resource_name: "invoices")
  end

  let!(:default_table_config) do
    TableConfig.create!(
      company: company,
      category: default_category,
      property_mapping: default_category.default_property_mapping,
      resource_name: "invoices",
      columns_metadata: [
        { "key" => "name", "label" => "Invoice Name", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
        { "key" => "code", "label" => "Code", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
        { "key" => "workflow_status", "label" => "Status", "visible" => true, "sortable" => true, "align" => "center", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} }
      ]
    )
  end

  let(:customer) do
    Seed::CustomerService.create(company: company, name: "Test Customer")
  end

  let(:order) do
    Seed::OrderService.create(company: company, customer: customer, name: "Test Order for Invoice Permissions")
  end

  # =========================================================================
  # ROLES
  # =========================================================================
  let!(:reader_role) { create(:role, company: company, name: "Reader", business_type: :support) }
  let!(:creator_role) { create(:role, company: company, name: "Creator", business_type: :support) }
  let!(:editor_role) { create(:role, company: company, name: "Editor", business_type: :management) }

  # =========================================================================
  # POLICIES
  # =========================================================================
  let!(:policy_read_invoice) { create_policy(resource: "Invoice", action: "read") }
  let!(:policy_create_invoice) { create_policy(resource: "Invoice", action: "create") }
  let!(:policy_update_invoice) { create_policy(resource: "Invoice", action: "update") }

  # Reader role: Invoice(read) - active
  let!(:reader_read_invoice_active) do
    create_policy_appointment(role: reader_role, policy: policy_read_invoice, workflow_status: :active)
  end

  # Creator role: Invoice(read, create) - active
  let!(:creator_read_invoice_active) do
    create_policy_appointment(role: creator_role, policy: policy_read_invoice, workflow_status: :active)
  end
  let!(:creator_create_invoice_active) do
    create_policy_appointment(role: creator_role, policy: policy_create_invoice, workflow_status: :active)
  end

  # Editor role: Invoice(read, update) - active
  let!(:editor_read_invoice_active) do
    create_policy_appointment(role: editor_role, policy: policy_read_invoice, workflow_status: :active)
  end
  let!(:editor_update_invoice_active) do
    create_policy_appointment(role: editor_role, policy: policy_update_invoice, workflow_status: :active)
  end

  # =========================================================================
  # EMPLOYEES
  # =========================================================================
  let!(:reader_user) { create(:user, :company_employee) }
  let!(:reader_employee) do
    emp = create(:employee, company: company, user: reader_user)
    create(:role_appointment, company: company, appoint_to: emp, role: reader_role)
    emp
  end

  let!(:creator_user) { create(:user, :company_employee) }
  let!(:creator_employee) do
    emp = create(:employee, company: company, user: creator_user)
    create(:role_appointment, company: company, appoint_to: emp, role: creator_role)
    emp
  end

  let!(:editor_user) { create(:user, :company_employee) }
  let!(:editor_employee) do
    emp = create(:employee, company: company, user: editor_user)
    create(:role_appointment, company: company, appoint_to: emp, role: editor_role)
    emp
  end

  # =========================================================================
  # INVOICE RECORDS
  # =========================================================================
  let!(:invoice) do
    Seed::InvoiceService.create(
      order: order,
      name: "Invoice for Permissions",
      business_type: "sales",
      workflow_status: "draft"
    )
  end

  # =========================================================================
  # HELPERS
  # =========================================================================
  def create_policy(resource:, action:, business_type: :operational)
    Seed::PolicyService.create(
      company: company,
      name: "Can #{action} #{resource}",
      resource: resource,
      action: action,
      business_type: business_type,
      lifecycle_status: :active
    )
  end

  def create_policy_appointment(role:, policy:, workflow_status:)
    appointment = PolicyAppointment.find_or_create_by!(
      company: company,
      policy: policy,
      appoint_to: role
    )
    appointment.update!(workflow_status: workflow_status)
    appointment
  end

  def seed_client_cache
    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.reload.to_json).merge(
      "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
      "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
      "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
      "branches" => [],
      "departments" => [],
      "roles" => []
    )

    payload = {
      user: JSON.parse(owner.reload.to_json),
      companies: [ company_data ],
      enums: {
        invoice: {
          business_types: [
            { name: "sales", value: "sales" },
            { name: "service", value: "service" },
            { name: "subscription", value: "subscription" }
          ],
          workflow_statuses: [
            { name: "Draft", value: "draft" },
            { name: "Pending", value: "pending" },
            { name: "Confirmed", value: "confirmed" },
            { name: "In progress", value: "in_progress" },
            { name: "Completed", value: "completed" },
            { name: "Paid", value: "paid" },
            { name: "Cancelled", value: "cancelled" },
            { name: "Refunded", value: "refunded" },
            { name: "Failed", value: "failed" }
          ],
          currency_codes: [
            { name: "usd", value: "usd" },
            { name: "vnd", value: "vnd" }
          ]
        }
      },
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  before do
    company.clear_permissions_cache
  end

  # =========================================================================
  # SCENARIO 1: Reader with only READ permission can see dashboard
  # =========================================================================
  scenario "employee with read-only permission can access invoices dashboard" do
    sign_in(reader_user)
    seed_client_cache
    visit company_invoices_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_content(invoice.name)
  end

  # =========================================================================
  # SCENARIO 2: Reader can? only read
  # =========================================================================
  scenario "employee without create permission cannot create invoice - can? returns false" do
    reader_employee.clear_permissions_cache
    reader_employee.reload

    expect(reader_employee.can?(:read, Invoice)).to be_truthy
    expect(reader_employee.can?(:create, Invoice)).to be_falsey
    expect(reader_employee.can?(:update, Invoice)).to be_falsey
  end

  # =========================================================================
  # SCENARIO 3: Creator can read and create
  # =========================================================================
  scenario "employee with create permission can? returns correct values" do
    creator_employee.clear_permissions_cache
    creator_employee.reload

    expect(creator_employee.can?(:read, Invoice)).to be_truthy
    expect(creator_employee.can?(:create, Invoice)).to be_truthy
    expect(creator_employee.can?(:update, Invoice)).to be_falsey
  end

  scenario "employee with create permission can access new invoice page" do
    creator_employee.clear_permissions_cache
    company.clear_permissions_cache
    creator_employee.reload

    sign_in(creator_user)
    seed_client_cache
    visit new_company_invoice_path(company)

    expect(page).to have_selector('input[name="invoice[name]"]', wait: 10)
  end

  # =========================================================================
  # SCENARIO 4: Editor can read and update
  # =========================================================================
  scenario "employee with update permission can? returns correct values" do
    editor_employee.clear_permissions_cache
    editor_employee.reload

    expect(editor_employee.can?(:read, Invoice)).to be_truthy
    expect(editor_employee.can?(:create, Invoice)).to be_falsey
    expect(editor_employee.can?(:update, Invoice)).to be_truthy
  end

  scenario "editor can edit an existing invoice" do
    editor_employee.clear_permissions_cache
    company.clear_permissions_cache
    editor_employee.reload

    sign_in(editor_user)
    seed_client_cache
    visit edit_company_invoice_path(company, invoice)

    expect(page).to have_selector('input[name="invoice[name]"]', wait: 10)

    new_name = "Updated Invoice Name"
    fill_in "invoice[name]", with: new_name
    click_button "Save Changes"

    expect(page).to have_current_path(/invoices\/#{invoice.id}$/, wait: 10)
    expect(page).to have_content(new_name, wait: 10)
    expect(invoice.reload.name).to eq(new_name)
  end

  # =========================================================================
  # SCENARIO 5: Owner has all permissions bypass
  # =========================================================================
  scenario "owner can? returns true for all actions" do
    owner_employee = company.employees.find_by(user: owner)

    expect(owner_employee.can?(:read, Invoice)).to be_truthy
    expect(owner_employee.can?(:create, Invoice)).to be_truthy
    expect(owner_employee.can?(:update, Invoice)).to be_truthy
  end
end
