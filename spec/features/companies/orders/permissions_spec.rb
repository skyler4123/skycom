require "rails_helper"

RSpec.feature "Companies::Orders Permissions", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  let!(:default_category) do
    Seed::CategoryService.find_or_create_for(company: company, resource_name: "orders")
  end

  let!(:default_table_config) do
    default_category.default_property_mapping.table_configs.destroy_all
    TableConfig.create!(
      company: company,
      category: default_category,
      property_mapping: default_category.default_property_mapping,
      resource_name: "orders",
      columns_metadata: [
        { "key" => "name", "label" => "Order Name", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
        { "key" => "code", "label" => "Code", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
        { "key" => "workflow_status", "label" => "Status", "visible" => true, "sortable" => true, "align" => "center", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} }
      ]
    )
  end

  let!(:customer) do
    Seed::CustomerService.create(company: company, name: "Test Customer")
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
  let!(:policy_read_order) { create_policy(resource: "Order", action: "read") }
  let!(:policy_create_order) { create_policy(resource: "Order", action: "create") }
  let!(:policy_update_order) { create_policy(resource: "Order", action: "update") }

  # Reader role: Order(read) - active
  let!(:reader_read_order_active) do
    create_policy_appointment(role: reader_role, policy: policy_read_order, workflow_status: :active)
  end

  # Creator role: Order(read, create) - active
  let!(:creator_read_order_active) do
    create_policy_appointment(role: creator_role, policy: policy_read_order, workflow_status: :active)
  end
  let!(:creator_create_order_active) do
    create_policy_appointment(role: creator_role, policy: policy_create_order, workflow_status: :active)
  end

  # Editor role: Order(read, update) - active
  let!(:editor_read_order_active) do
    create_policy_appointment(role: editor_role, policy: policy_read_order, workflow_status: :active)
  end
  let!(:editor_update_order_active) do
    create_policy_appointment(role: editor_role, policy: policy_update_order, workflow_status: :active)
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
  # ORDER RECORDS
  # =========================================================================
  let!(:order) do
    Seed::OrderService.create(
      company: company,
      customer: customer,
      name: "Order for Permissions",
      business_type: "online",
      workflow_status: "draft",
      category: default_category
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
        order: {
          business_types: [
            { name: "online", value: "online" },
            { name: "in_store", value: "in_store" },
            { name: "phone", value: "phone" }
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
  scenario "employee with read-only permission can access orders dashboard" do
    sign_in(reader_user)
    seed_client_cache
    visit company_orders_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_content(order.name)
  end

  # =========================================================================
  # SCENARIO 2: Reader can? only read
  # =========================================================================
  scenario "employee without create permission cannot create order - can? returns false" do
    reader_employee.clear_permissions_cache
    reader_employee.reload

    expect(reader_employee.can?(:read, Order)).to be_truthy
    expect(reader_employee.can?(:create, Order)).to be_falsey
    expect(reader_employee.can?(:update, Order)).to be_falsey
  end

  # =========================================================================
  # SCENARIO 3: Creator can read and create
  # =========================================================================
  scenario "employee with create permission can? returns correct values" do
    creator_employee.clear_permissions_cache
    creator_employee.reload

    expect(creator_employee.can?(:read, Order)).to be_truthy
    expect(creator_employee.can?(:create, Order)).to be_truthy
    expect(creator_employee.can?(:update, Order)).to be_falsey
  end

  scenario "employee with create permission can access new order page" do
    creator_employee.clear_permissions_cache
    company.clear_permissions_cache
    creator_employee.reload

    sign_in(creator_user)
    seed_client_cache
    visit new_company_order_path(company)

    expect(page).to have_selector('input[name="order[name]"]', wait: 10)
  end

  scenario "creator can see order details on show page" do
    creator_employee.clear_permissions_cache
    company.clear_permissions_cache
    creator_employee.reload

    sign_in(creator_user)
    seed_client_cache
    visit company_order_path(company, order)

    expect(page).to have_selector('h2', text: order.name, wait: 10)
  end

  scenario "creator can reach show page from index" do
    creator_employee.clear_permissions_cache
    company.clear_permissions_cache
    creator_employee.reload

    sign_in(creator_user)
    seed_client_cache
    visit company_orders_path(company)

    expect(page).to have_selector('table', wait: 10)

    name_link = find("a[href*='/orders/#{order.id}']", match: :first)
    expect(name_link).to be_present
  end

  # =========================================================================
  # SCENARIO 4: Editor can read and update
  # =========================================================================
  scenario "employee with update permission can? returns correct values" do
    editor_employee.clear_permissions_cache
    editor_employee.reload

    expect(editor_employee.can?(:read, Order)).to be_truthy
    expect(editor_employee.can?(:create, Order)).to be_falsey
    expect(editor_employee.can?(:update, Order)).to be_truthy
  end

  scenario "editor can edit an existing order" do
    editor_employee.clear_permissions_cache
    company.clear_permissions_cache
    editor_employee.reload

    sign_in(editor_user)
    seed_client_cache
    visit edit_company_order_path(company, order)

    expect(page).to have_selector('input[name="order[name]"]', wait: 10)

    new_name = "Updated Order Name"
    fill_in "order[name]", with: new_name
    click_button "Save Changes"

    expect(page).to have_current_path(/orders\/#{order.id}$/, wait: 10)
    expect(page).to have_content(new_name, wait: 10)
    expect(order.reload.name).to eq(new_name)
  end

  # =========================================================================
  # SCENARIO 5: Owner has all permissions bypass
  # =========================================================================
  scenario "owner can? returns true for all actions" do
    owner_employee = company.employees.find_by(user: owner)

    expect(owner_employee.can?(:read, Order)).to be_truthy
    expect(owner_employee.can?(:create, Order)).to be_truthy
    expect(owner_employee.can?(:update, Order)).to be_truthy
  end
end
