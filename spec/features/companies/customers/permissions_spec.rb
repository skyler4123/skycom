require "rails_helper"

RSpec.feature "Companies::Customers Permissions", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:owner) { company.user }

  # Roles
  let!(:reader_role) { create(:role, company: company, name: "Reader", business_type: :support) }
  let!(:creator_role) { create(:role, company: company, name: "Creator", business_type: :support) }
  let!(:editor_role) { create(:role, company: company, name: "Editor", business_type: :management) }
  let!(:no_permission_role) { create(:role, company: company, name: "NoPermission", business_type: :support) }

  # Policies for Customer resource
  let!(:policy_read_customer) { create_policy(resource: "Customer", action: "read") }
  let!(:policy_create_customer) { create_policy(resource: "Customer", action: "create") }
  let!(:policy_update_customer) { create_policy(resource: "Customer", action: "update") }

  # Reader role: Customer(read) - active
  let!(:reader_read_customer_active) do
    create_policy_appointment(role: reader_role, policy: policy_read_customer, workflow_status: :active)
  end

  # Creator role: Customer(read, create) - active
  let!(:creator_read_customer_active) do
    create_policy_appointment(role: creator_role, policy: policy_read_customer, workflow_status: :active)
  end
  let!(:creator_create_customer_active) do
    create_policy_appointment(role: creator_role, policy: policy_create_customer, workflow_status: :active)
  end

  # Editor role: Customer(read, update) - active
  let!(:editor_read_customer_active) do
    create_policy_appointment(role: editor_role, policy: policy_read_customer, workflow_status: :active)
  end
  let!(:editor_update_customer_active) do
    create_policy_appointment(role: editor_role, policy: policy_update_customer, workflow_status: :active)
  end

  # NoPermission role: NO policies for Customer

  # Test employees with different roles
  let!(:reader_user) { create(:user, :company_employee) }
  let!(:reader_employee) do
    emp = create(:employee, company: company, branch: branch, user: reader_user)
    create(:role_appointment, company: company, appoint_to: emp, role: reader_role)
    emp
  end

  let!(:creator_user) { create(:user, :company_employee) }
  let!(:creator_employee) do
    emp = create(:employee, company: company, branch: branch, user: creator_user)
    create(:role_appointment, company: company, appoint_to: emp, role: creator_role)
    emp
  end

  let!(:editor_user) { create(:user, :company_employee) }
  let!(:editor_employee) do
    emp = create(:employee, company: company, branch: branch, user: editor_user)
    create(:role_appointment, company: company, appoint_to: emp, role: editor_role)
    emp
  end

  let!(:no_permission_user) { create(:user, :company_employee) }
  let!(:no_permission_employee) do
    emp = create(:employee, company: company, branch: branch, user: no_permission_user)
    create(:role_appointment, company: company, appoint_to: emp, role: no_permission_role)
    emp
  end

  # Target customer for edit tests
  let!(:target_customer) do
    Seed::CustomerService.create(
      company: company,
      name: "Target Customer",
      email: "target@example.com",
      description: "Test description",
      business_type: "individual"
    )
  end

  def create_policy(resource:, action:, business_type: :operational)
    Seed::PolicyService.create(
      company: company,
      branch: branch,
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
        customer: {
          business_types: [
            { name: "Individual", value: "individual" },
            { name: "Small business", value: "small_business" },
            { name: "Enterprise", value: "enterprise" }
          ],
          workflow_statuses: [
            { name: "Draft", value: "draft" },
            { name: "Pending", value: "pending" },
            { name: "Confirmed", value: "confirmed" }
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
  scenario "employee with read-only permission can access customers dashboard" do
    sign_in(reader_user)
    seed_client_cache
    visit company_customers_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_content("Customer Name")
  end

  scenario "reader can? returns true for read, false for create/update" do
    reader_employee.clear_permissions_cache
    reader_employee.reload

    expect(reader_employee.can?(:read, Customer)).to be_truthy
    expect(reader_employee.can?(:create, Customer)).to be_falsey
    expect(reader_employee.can?(:update, Customer)).to be_falsey
  end

  scenario "read-only employee can see Add link in UI (UI doesn't gate on permissions)" do
    reader_employee.clear_permissions_cache
    sign_in(reader_user)
    seed_client_cache
    visit company_customers_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_link('Add', wait: 10)
  end

  # =========================================================================
  # SCENARIO 2: Creator with READ+CREATE can create customer
  # =========================================================================
  scenario "employee with create permission can see Add link" do
    creator_employee.clear_permissions_cache
    sign_in(creator_user)
    seed_client_cache
    visit company_customers_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_link('Add', wait: 5)
  end

  scenario "employee with create permission can access new customer page" do
    creator_employee.clear_permissions_cache
    company.clear_permissions_cache
    creator_employee.reload

    sign_in(creator_user)
    seed_client_cache
    visit new_company_customer_path(company)

    expect(page).to have_selector('input[name="customer[name]"]', wait: 10)
  end

  scenario "creator can create new customer and see in table" do
    creator_employee.clear_permissions_cache
    company.clear_permissions_cache
    creator_employee.reload

    sign_in(creator_user)
    seed_client_cache
    visit new_company_customer_path(company)

    expect(page).to have_selector('input[name="customer[name]"]', wait: 10)
    fill_in 'customer[name]', with: 'Created by Creator'
    fill_in 'customer[email]', with: 'creator@example.com'
    page.execute_script("document.querySelector('select[name=\"customer[business_type]\"]').value = 'individual'")

    click_button "Save Customer"

    new_customer = Customer.find_by(name: "Created by Creator")
    expect(page).to have_current_path(/customers\/#{new_customer.id}$/, wait: 10)
    expect(page).to have_content("Created by Creator", wait: 10)

    expect(Customer.find_by(name: "Created by Creator")).to be_present
  end

  scenario "creator can? returns true for read and create" do
    creator_employee.clear_permissions_cache
    creator_employee.reload

    expect(creator_employee.can?(:read, Customer)).to be_truthy
    expect(creator_employee.can?(:create, Customer)).to be_truthy
    expect(creator_employee.can?(:update, Customer)).to be_falsey
  end

  # =========================================================================
  # SCENARIO 2a: Employee WITHOUT create permission gets error when trying to create
  # =========================================================================
  scenario "employee without create permission cannot access new customer page" do
    sign_in(owner)
    seed_client_cache
    visit company_permissions_path(company)

    no_permission_section = find('.role-section', text: "NoPermission")

    unless no_permission_section.has_content?("Can read Customer")
      no_permission_section.click_button("Add Resource")
      within(".swal2-html-container") do
        select "Customer", from: "permission[resource_name]"
        click_button "Add Resource"
      end
      expect(page).to have_content("Resource added successfully", wait: 10)
    end

    no_permission_section = find('.role-section', text: "NoPermission")
    read_label = no_permission_section.all('label').find { |l| l.text.include?("Can read Customer") }
    read_checkbox = read_label.find('input[type="checkbox"]')

    unless read_checkbox.checked?
      accept_confirm do
        read_checkbox.click
      end
      expect(page).to have_selector('input[type="checkbox"]:checked', wait: 10)
    end

    company.clear_permissions_cache

    sign_in(no_permission_user)
    visit new_company_customer_path(company)

    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)

    expect(Customer.find_by(name: "Should Not Be Created")).to be_nil
  end

  # =========================================================================
  # SCENARIO 3: Editor with READ+UPDATE can edit customer
  # =========================================================================
  scenario "employee with update permission can see table with edit links" do
    editor_employee.clear_permissions_cache
    sign_in(editor_user)
    seed_client_cache
    visit company_customers_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_link(href: /\/edit$/, minimum: 1)
  end

  scenario "editor can? returns true for read and update" do
    editor_employee.clear_permissions_cache
    editor_employee.reload

    expect(editor_employee.can?(:read, Customer)).to be_truthy
    expect(editor_employee.can?(:create, Customer)).to be_falsey
    expect(editor_employee.can?(:update, Customer)).to be_truthy
  end

  # =========================================================================
  # SCENARIO 3b: Editor can update customer name via edit page
  # =========================================================================
  scenario "editor with update permission can update customer name via edit page" do
    editor_employee.clear_permissions_cache
    company.clear_permissions_cache
    editor_employee.reload

    sign_in(editor_user)
    seed_client_cache
    visit edit_company_customer_path(company, target_customer)

    expect(page).to have_selector('input[name="customer[name]"]', wait: 10)

    fill_in 'customer[name]', with: 'Updated Customer Name'
    click_button "Save Changes"

    expect(page).to have_current_path(/customers\/#{target_customer.id}$/, wait: 10)
    expect(page).to have_content("Updated Customer Name", wait: 10)
    expect(target_customer.reload.name).to eq("Updated Customer Name")
  end

  # =========================================================================
  # SCENARIO 3c: Employee WITHOUT update permission gets error when editing
  # =========================================================================
  scenario "employee without update permission cannot access edit customer page" do
    sign_in(owner)
    seed_client_cache
    visit company_permissions_path(company)

    editor_section = find('.role-section', text: "Editor")

    unless editor_section.has_content?("Can update Customer")
      editor_section.click_button("Add Resource")
      within(".swal2-html-container") do
        select "Customer", from: "permission[resource_name]"
        click_button "Add Resource"
      end
      expect(page).to have_content("Resource added successfully", wait: 10)
    end

    company.clear_permissions_cache

    # Remove update permission from editor temporarily by setting workflow_status to inactive
    appointment = PolicyAppointment.find_by(appoint_to: editor_role, policy: policy_update_customer)
    appointment.update!(workflow_status: :inactive)
    company.clear_permissions_cache
    editor_employee.reload

    expect(editor_employee.can?(:update, Customer)).to be_falsey

    # Try to access edit page - should fail with authorization error
    sign_in(editor_user)
    visit edit_company_customer_path(company, target_customer)

    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)

    target_customer.reload
    expect(target_customer.name).not_to eq("Attempted Update")
  end

  # =========================================================================
  # SCENARIO 4: Owner has all permissions bypass
  # =========================================================================
  scenario "owner can? returns true for all actions" do
    owner_employee = company.employees.find_by(user: owner)

    expect(owner_employee.can?(:read, Customer)).to be_truthy
    expect(owner_employee.can?(:create, Customer)).to be_truthy
    expect(owner_employee.can?(:update, Customer)).to be_truthy
  end

  # =========================================================================
  # SCENARIO 5: Permission changes via UI toggle work correctly
  # =========================================================================
  scenario "policy appointment workflow_status can be toggled to grant permission" do
    # NoPermission role initially has no Customer create permission
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload
    expect(no_permission_employee.can?(:create, Customer)).to be_falsey

    # Grant permission via policy appointment
    sign_in(owner)
    seed_client_cache
    visit company_permissions_path(company)

    no_permission_section = find('.role-section', text: "NoPermission")

    # Add Customer resource if not present
    unless no_permission_section.has_content?("Can create Customer")
      no_permission_section.click_button("Add Resource")
      within(".swal2-html-container") do
        select "Customer", from: "permission[resource_name]"
        click_button "Add Resource"
      end
      expect(page).to have_content("Resource added successfully", wait: 10)
    end

    # Activate create permission
    no_permission_section = find('.role-section', text: "NoPermission")
    create_label = no_permission_section.all('label').find { |l| l.text.include?("Can create Customer") }

    if create_label
      create_checkbox = create_label.find('input[type="checkbox"]')
      unless create_checkbox.checked?
        accept_confirm do
          create_checkbox.click
        end
      end
    end

    company.clear_permissions_cache
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload
    expect(no_permission_employee.can?(:create, Customer)).to be_truthy
  end

  # =========================================================================
  # SCENARIO 6: Deactivating policy appointment revokes permission
  # =========================================================================
  scenario "policy appointment workflow_status can be toggled to revoke permission" do
    # Editor role initially has Customer update permission
    editor_employee.clear_permissions_cache
    editor_employee.reload
    expect(editor_employee.can?(:update, Customer)).to be_truthy

    # Find and deactivate the update permission
    appointment = PolicyAppointment.find_by(appoint_to: editor_role, policy: policy_update_customer)
    appointment.update!(workflow_status: :inactive)
    company.clear_permissions_cache

    editor_employee.reload
    expect(editor_employee.can?(:update, Customer)).to be_falsey
  end

  # =========================================================================
  # SCENARIO 7: No permission employee cannot access customer dashboard
  # =========================================================================
  scenario "employee without read permission cannot access customers dashboard" do
    # NoPermission role has no Customer policies at all
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload

    expect(no_permission_employee.can?(:read, Customer)).to be_falsey

    sign_in(no_permission_user)
    visit company_customers_path(company)

    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)
  end
end
