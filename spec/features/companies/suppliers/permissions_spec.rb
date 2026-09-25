require "rails_helper"

RSpec.feature "Companies::Suppliers Permissions", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:owner) { company.user }

  # Roles
  let!(:reader_role) { create(:role, company: company, name: "Reader", business_type: :support) }
  let!(:creator_role) { create(:role, company: company, name: "Creator", business_type: :support) }
  let!(:editor_role) { create(:role, company: company, name: "Editor", business_type: :management) }
  let!(:no_permission_role) { create(:role, company: company, name: "NoPermission", business_type: :support) }

  # Policies for Supplier resource
  let!(:policy_read_supplier) { create_policy(resource: "Supplier", action: "read") }
  let!(:policy_create_supplier) { create_policy(resource: "Supplier", action: "create") }
  let!(:policy_update_supplier) { create_policy(resource: "Supplier", action: "update") }

  # Reader role: Supplier(read) - active
  let!(:reader_read_supplier_active) do
    create_policy_appointment(role: reader_role, policy: policy_read_supplier, workflow_status: :active)
  end

  # Creator role: Supplier(read, create) - active
  let!(:creator_read_supplier_active) do
    create_policy_appointment(role: creator_role, policy: policy_read_supplier, workflow_status: :active)
  end
  let!(:creator_create_supplier_active) do
    create_policy_appointment(role: creator_role, policy: policy_create_supplier, workflow_status: :active)
  end

  # Editor role: Supplier(read, update) - active
  let!(:editor_read_supplier_active) do
    create_policy_appointment(role: editor_role, policy: policy_read_supplier, workflow_status: :active)
  end
  let!(:editor_update_supplier_active) do
    create_policy_appointment(role: editor_role, policy: policy_update_supplier, workflow_status: :active)
  end

  # NoPermission role: NO policies for Supplier

  # Test employees with different roles
  let!(:reader_user) { create(:user, :company_employee) }
  let!(:reader_employee) do
    emp = create(:employee, company: company, branch: branch, user: reader_user)
    create(:employee_role_appointment, company: company, employee: emp, role: reader_role)
    emp
  end

  let!(:creator_user) { create(:user, :company_employee) }
  let!(:creator_employee) do
    emp = create(:employee, company: company, branch: branch, user: creator_user)
    create(:employee_role_appointment, company: company, employee: emp, role: creator_role)
    emp
  end

  let!(:editor_user) { create(:user, :company_employee) }
  let!(:editor_employee) do
    emp = create(:employee, company: company, branch: branch, user: editor_user)
    create(:employee_role_appointment, company: company, employee: emp, role: editor_role)
    emp
  end

  let!(:no_permission_user) { create(:user, :company_employee) }
  let!(:no_permission_employee) do
    emp = create(:employee, company: company, branch: branch, user: no_permission_user)
    create(:employee_role_appointment, company: company, employee: emp, role: no_permission_role)
    emp
  end

  # Target supplier for edit tests
  let!(:target_supplier) { create(:supplier, company: company, name: "Target Supplier") }

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
    appointment = PolicyRoleAppointment.find_or_create_by!(
      company: company,
      policy: policy,
      role: role
    )
    appointment.update!(workflow_status: workflow_status)
    appointment
  end

  def toggle_policy(role_text:, action:, resource:)
    role_el = find('.role-section', text: role_text)
    resource_el = role_el.find('.resource-section', text: resource)
    badge = resource_el.all('button').find { |b| b.text.match?(/#{action}/i) }

    badge.click
    within(".swal2-html-container") do
      find('[data-status-toggle]').click
      click_button "Save"
    end
    expect(page).to have_content("#{action} permission updated", wait: 10)
  end

  before do
    company.clear_permissions_cache
  end

  # =========================================================================
  # SCENARIO 1: Reader with only READ permission can see dashboard
  # =========================================================================
  scenario "employee with read-only permission can access suppliers dashboard" do
    sign_in(reader_user)
    visit company_suppliers_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_content("Supplier Name")
  end

  scenario "reader can? returns true for read, false for create/update" do
    reader_employee.clear_permissions_cache
    reader_employee.reload

    expect(reader_employee.can?(:read, Supplier)).to be_truthy
    expect(reader_employee.can?(:create, Supplier)).to be_falsey
    expect(reader_employee.can?(:update, Supplier)).to be_falsey
  end

  scenario "read-only employee can see Add link in UI (UI doesn't gate on permissions)" do
    reader_employee.clear_permissions_cache
    sign_in(reader_user)
    visit company_suppliers_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('a', text: 'Add')
  end

  # =========================================================================
  # SCENARIO 2: Creator with READ+CREATE can create supplier
  # =========================================================================
  scenario "employee with create permission can see Add link" do
    creator_employee.clear_permissions_cache
    sign_in(creator_user)
    visit company_suppliers_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('a', text: 'Add', wait: 5)
  end

  scenario "employee with create permission can access new page" do
    creator_employee.clear_permissions_cache
    sign_in(creator_user)
    visit new_company_supplier_path(company)

    expect(page).to have_selector('input[name="supplier[name]"]', wait: 10)
  end

  scenario "creator can create new supplier and see in table" do
    creator_employee.clear_permissions_cache
    company.clear_permissions_cache
    creator_employee.reload

    sign_in(creator_user)
    visit new_company_supplier_path(company)

    expect(page).to have_selector('input[name="supplier[name]"]', wait: 10)
    fill_in 'supplier[name]', with: 'Created by Creator'
    select 'Manufacturer', from: 'supplier[business_type]'

    click_button "Save Supplier"

    expect(page).to have_content('Created by Creator', wait: 10)

    expect(Supplier.find_by(name: "Created by Creator")).to be_present
  end

  scenario "creator can? returns true for read and create" do
    creator_employee.clear_permissions_cache
    creator_employee.reload

    expect(creator_employee.can?(:read, Supplier)).to be_truthy
    expect(creator_employee.can?(:create, Supplier)).to be_truthy
    expect(creator_employee.can?(:update, Supplier)).to be_falsey
  end

  # =========================================================================
  # SCENARIO 2a: Employee WITHOUT create permission gets error when trying to create
  # =========================================================================
  scenario "employee without create permission cannot access new page" do
    sign_in(owner)
    visit company_permissions_path(company)

    no_permission_section = find('.role-section', text: "NoPermission")

    unless no_permission_section.has_content?("Can read Supplier")
      no_permission_section.click_button("Add Resource")
      within(".swal2-html-container") do
        select "Supplier", from: "permission[resource_name]"
        click_button "Add Resource"
      end
      expect(page).to have_content("Resource added successfully", wait: 10)
    end

    toggle_policy(role_text: "NoPermission", action: "read", resource: "Supplier")

    company.clear_permissions_cache

    sign_in(no_permission_user)
    visit new_company_supplier_path(company)

    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)
  end

  # =========================================================================
  # SCENARIO 3: Editor with READ+UPDATE can edit supplier
  # =========================================================================
  scenario "employee with update permission can see table with edit links" do
    editor_employee.clear_permissions_cache
    sign_in(editor_user)
    visit company_suppliers_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('a[href*="/edit"]', minimum: 1)
  end

  scenario "editor can? returns true for read and update" do
    editor_employee.clear_permissions_cache
    editor_employee.reload

    expect(editor_employee.can?(:read, Supplier)).to be_truthy
    expect(editor_employee.can?(:create, Supplier)).to be_falsey
    expect(editor_employee.can?(:update, Supplier)).to be_truthy
  end

  scenario "editor with update permission can update supplier name via edit page" do
    editor_employee.clear_permissions_cache
    company.clear_permissions_cache
    editor_employee.reload

    sign_in(editor_user)
    visit edit_company_supplier_path(company, target_supplier)

    expect(page).to have_selector('input[name="supplier[name]"]', wait: 10)
    fill_in 'supplier[name]', with: 'Updated Supplier Name'

    click_button "Save Changes"

    expect(page).to have_content('Updated Supplier Name', wait: 10)
    expect(Supplier.find_by(id: target_supplier.id).name).to eq("Updated Supplier Name")
  end

  # =========================================================================
  # SCENARIO 3d: Employee WITHOUT update permission gets error when editing
  # =========================================================================
  scenario "employee without update permission cannot access edit page" do
    sign_in(owner)
    visit company_permissions_path(company)

    editor_section = find('.role-section', text: "Editor")

    unless editor_section.has_css?('.resource-section', text: 'Supplier')
      editor_section.click_button("Add Resource")
      within(".swal2-html-container") do
        select "Supplier", from: "permission[resource_name]"
        click_button "Add Resource"
      end
      expect(page).to have_content("Resource added successfully", wait: 10)
    end

    company.clear_permissions_cache

    # Remove update permission from editor temporarily
    appointment = PolicyRoleAppointment.find_by(role: editor_role, policy: policy_update_supplier)
    appointment.update!(workflow_status: :inactive)
    company.clear_permissions_cache
    editor_employee.reload

    expect(editor_employee.can?(:update, Supplier)).to be_falsey

    sign_in(editor_user)
    visit edit_company_supplier_path(company, target_supplier)

    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)

    target_supplier.reload
    expect(target_supplier.name).not_to eq("Attempted Update")
  end

  # =========================================================================
  # SCENARIO 4: Owner has all permissions bypass
  # =========================================================================
  scenario "owner can? returns true for all actions" do
    owner_employee = company.employees.find_by(user: owner)

    expect(owner_employee.can?(:read, Supplier)).to be_truthy
    expect(owner_employee.can?(:create, Supplier)).to be_truthy
    expect(owner_employee.can?(:update, Supplier)).to be_truthy
  end

  # =========================================================================
  # SCENARIO 5: Permission changes via UI toggle work correctly
  # =========================================================================
  scenario "policy appointment workflow_status can be toggled to grant permission" do
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload
    expect(no_permission_employee.can?(:create, Supplier)).to be_falsey

    sign_in(owner)
    visit company_permissions_path(company)

    no_permission_section = find('.role-section', text: "NoPermission")

    unless no_permission_section.has_content?("Can create Supplier")
      no_permission_section.click_button("Add Resource")
      within(".swal2-html-container") do
        select "Supplier", from: "permission[resource_name]"
        click_button "Add Resource"
      end
      expect(page).to have_content("Resource added successfully", wait: 10)
    end

    toggle_policy(role_text: "NoPermission", action: "create", resource: "Supplier")

    company.clear_permissions_cache
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload
    expect(no_permission_employee.can?(:create, Supplier)).to be_truthy
  end

  # =========================================================================
  # SCENARIO 6: Deactivating policy appointment revokes permission
  # =========================================================================
  scenario "policy appointment workflow_status can be toggled to revoke permission" do
    editor_employee.clear_permissions_cache
    editor_employee.reload
    expect(editor_employee.can?(:update, Supplier)).to be_truthy

    appointment = PolicyRoleAppointment.find_by(role: editor_role, policy: policy_update_supplier)
    appointment.update!(workflow_status: :inactive)
    company.clear_permissions_cache

    editor_employee.reload
    expect(editor_employee.can?(:update, Supplier)).to be_falsey
  end

  # =========================================================================
  # SCENARIO 7: No permission employee cannot access supplier dashboard
  # =========================================================================
  scenario "employee without read permission cannot access suppliers dashboard" do
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload

    expect(no_permission_employee.can?(:read, Supplier)).to be_falsey

    sign_in(no_permission_user)
    visit company_suppliers_path(company)

    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)
  end
end
