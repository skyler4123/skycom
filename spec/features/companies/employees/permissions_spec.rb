require "rails_helper"

RSpec.feature "Companies::Employees Permissions", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:owner) { company.user }

  # Roles
  let!(:reader_role) { create(:role, company: company, name: "Reader", business_type: :support) }
  let!(:creator_role) { create(:role, company: company, name: "Creator", business_type: :support) }
  let!(:editor_role) { create(:role, company: company, name: "Editor", business_type: :management) }
  let!(:no_permission_role) { create(:role, company: company, name: "NoPermission", business_type: :support) }

  # Policies for Employee resource
  let!(:policy_read_employee) { create_policy(resource: "Employee", action: "read") }
  let!(:policy_create_employee) { create_policy(resource: "Employee", action: "create") }
  let!(:policy_update_employee) { create_policy(resource: "Employee", action: "update") }

  # Reader role: Employee(read) - active
  let!(:reader_read_employee_active) do
    create_policy_appointment(role: reader_role, policy: policy_read_employee, workflow_status: :active)
  end

  # Creator role: Employee(read, create) - active
  let!(:creator_read_employee_active) do
    create_policy_appointment(role: creator_role, policy: policy_read_employee, workflow_status: :active)
  end
  let!(:creator_create_employee_active) do
    create_policy_appointment(role: creator_role, policy: policy_create_employee, workflow_status: :active)
  end

  # Editor role: Employee(read, update) - active
  let!(:editor_read_employee_active) do
    create_policy_appointment(role: editor_role, policy: policy_read_employee, workflow_status: :active)
  end
  let!(:editor_update_employee_active) do
    create_policy_appointment(role: editor_role, policy: policy_update_employee, workflow_status: :active)
  end

  # NoPermission role: NO policies for Employee

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

  # Target employee for edit tests
  let!(:target_employee) { create(:employee, company: company, branch: branch, name: "Target Employee") }

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
        employee: {
          business_types: [
            { name: "Full Time", value: "full_time" },
            { name: "Part Time", value: "part_time" },
            { name: "Contractor", value: "contractor" },
            { name: "Intern", value: "intern" }
          ],
          workflow_statuses: [
            { name: "Draft", value: "draft" },
            { name: "Pending", value: "pending" },
            { name: "Active", value: "active" },
            { name: "Inactive", value: "inactive" }
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
  scenario "employee with read-only permission can access employees dashboard" do
    sign_in(reader_user)
    visit company_employees_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_content("Employee Name")
  end

  scenario "reader can? returns true for read, false for create/update" do
    reader_employee.clear_permissions_cache
    reader_employee.reload

    expect(reader_employee.can?(:read, Employee)).to be_truthy
    expect(reader_employee.can?(:create, Employee)).to be_falsey
    expect(reader_employee.can?(:update, Employee)).to be_falsey
  end

  scenario "read-only employee can see Add link in UI (UI doesn't gate on permissions)" do
    reader_employee.clear_permissions_cache
    sign_in(reader_user)
    visit company_employees_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('a', text: 'Add')
  end

  # =========================================================================
  # SCENARIO 2: Creator with READ+CREATE can create employee
  # =========================================================================
  scenario "employee with create permission can see Add link" do
    creator_employee.clear_permissions_cache
    sign_in(creator_user)
    visit company_employees_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('a', text: 'Add', wait: 5)
  end

  scenario "employee with create permission can access new employee page" do
    creator_employee.clear_permissions_cache
    sign_in(creator_user)
    visit new_company_employee_path(company)

    expect(page).to have_selector('input[name="employee[name]"]', wait: 10)
  end

  scenario "creator can create new employee and see in table" do
    creator_employee.clear_permissions_cache
    company.clear_permissions_cache
    creator_employee.reload

    sign_in(creator_user)
    seed_client_cache
    visit new_company_employee_path(company)

    expect(page).to have_selector('input[name="employee[name]"]', wait: 10)
    fill_in 'employee[name]', with: 'Created by Creator'
    page.execute_script("document.querySelector('select[name=\"employee[business_type]\"]').value = 'full_time'")

    click_button "Save Employee"

    expect(page).to have_content('Created by Creator', wait: 10)

    expect(Employee.find_by(name: "Created by Creator")).to be_present
  end

  scenario "creator can? returns true for read and create" do
    creator_employee.clear_permissions_cache
    creator_employee.reload

    expect(creator_employee.can?(:read, Employee)).to be_truthy
    expect(creator_employee.can?(:create, Employee)).to be_truthy
    expect(creator_employee.can?(:update, Employee)).to be_falsey
  end

  # =========================================================================
  # SCENARIO 2a: Employee WITHOUT create permission gets error when trying to create
  # =========================================================================
  scenario "employee without create permission cannot access new employee page" do
    sign_in(owner)
    visit company_permissions_path(company)

    no_permission_section = find('.role-section', text: "NoPermission")

    unless no_permission_section.has_selector?('.resource-section', text: 'Employee')
      no_permission_section.click_button("Add Resource")
      within(".swal2-html-container") do
        select "Employee", from: "permission[resource_name]"
        click_button "Add Resource"
      end
      expect(page).to have_content("Resource added successfully", wait: 10)
    end

    toggle_policy(role_text: "NoPermission", action: "read", resource: "Employee")

    company.clear_permissions_cache

    sign_in(no_permission_user)
    visit new_company_employee_path(company)

    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)
  end

  # =========================================================================
  # SCENARIO 3: Editor with READ+UPDATE can edit employee
  # =========================================================================
  scenario "employee with update permission can see table with edit links" do
    editor_employee.clear_permissions_cache
    sign_in(editor_user)
    visit company_employees_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('a[href*="/edit"]', minimum: 1)
  end

  scenario "editor can? returns true for read and update" do
    editor_employee.clear_permissions_cache
    editor_employee.reload

    expect(editor_employee.can?(:read, Employee)).to be_truthy
    expect(editor_employee.can?(:create, Employee)).to be_falsey
    expect(editor_employee.can?(:update, Employee)).to be_truthy
  end

  scenario "editor with update permission can update employee name via edit page" do
    editor_employee.clear_permissions_cache
    company.clear_permissions_cache
    editor_employee.reload

    sign_in(editor_user)
    visit edit_company_employee_path(company, target_employee)

    expect(page).to have_selector('input[name="employee[name]"]', wait: 10)
    fill_in 'employee[name]', with: 'Updated Employee Name'

    click_button "Save Changes"

    expect(page).to have_content('Updated Employee Name', wait: 10)
    expect(Employee.find_by(id: target_employee.id).name).to eq("Updated Employee Name")
  end

  # =========================================================================
  # SCENARIO 3d: Employee WITHOUT update permission gets error when editing
  # =========================================================================
  scenario "employee without update permission cannot access edit page" do
    sign_in(owner)
    visit company_permissions_path(company)

    editor_section = find('.role-section', text: "Editor")

    unless editor_section.has_selector?('.resource-section', text: 'Employee')
      editor_section.click_button("Add Resource")
      within(".swal2-html-container") do
        select "Employee", from: "permission[resource_name]"
        click_button "Add Resource"
      end
      expect(page).to have_content("Resource added successfully", wait: 10)
    end

    company.clear_permissions_cache

    appointment = PolicyAppointment.find_by(appoint_to: editor_role, policy: policy_update_employee)
    appointment.update!(workflow_status: :inactive)
    company.clear_permissions_cache
    editor_employee.reload

    expect(editor_employee.can?(:update, Employee)).to be_falsey

    sign_in(editor_user)
    visit edit_company_employee_path(company, target_employee)

    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)

    target_employee.reload
    expect(target_employee.name).not_to eq("Attempted Update")
  end

  # =========================================================================
  # SCENARIO 4: Owner has all permissions bypass
  # =========================================================================
  scenario "owner can? returns true for all actions" do
    owner_employee = company.employees.find_by(user: owner)

    expect(owner_employee.can?(:read, Employee)).to be_truthy
    expect(owner_employee.can?(:create, Employee)).to be_truthy
    expect(owner_employee.can?(:update, Employee)).to be_truthy
  end

  # =========================================================================
  # SCENARIO 5: Permission changes via UI toggle work correctly
  # =========================================================================
  scenario "policy appointment workflow_status can be toggled to grant permission" do
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload
    expect(no_permission_employee.can?(:create, Employee)).to be_falsey

    sign_in(owner)
    visit company_permissions_path(company)

    no_permission_section = find('.role-section', text: "NoPermission")

    unless no_permission_section.has_selector?('.resource-section', text: 'Employee')
      no_permission_section.click_button("Add Resource")
      within(".swal2-html-container") do
        select "Employee", from: "permission[resource_name]"
        click_button "Add Resource"
      end
      expect(page).to have_content("Resource added successfully", wait: 10)
    end

    toggle_policy(role_text: "NoPermission", action: "create", resource: "Employee")

    company.clear_permissions_cache
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload
    expect(no_permission_employee.can?(:create, Employee)).to be_truthy
  end

  # =========================================================================
  # SCENARIO 6: Deactivating policy appointment revokes permission
  # =========================================================================
  scenario "policy appointment workflow_status can be toggled to revoke permission" do
    editor_employee.clear_permissions_cache
    editor_employee.reload
    expect(editor_employee.can?(:update, Employee)).to be_truthy

    appointment = PolicyAppointment.find_by(appoint_to: editor_role, policy: policy_update_employee)
    appointment.update!(workflow_status: :inactive)
    company.clear_permissions_cache

    editor_employee.reload
    expect(editor_employee.can?(:update, Employee)).to be_falsey
  end

  # =========================================================================
  # SCENARIO 7: No permission employee cannot access employee dashboard
  # =========================================================================
  scenario "employee without read permission cannot access employees dashboard" do
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload

    expect(no_permission_employee.can?(:read, Employee)).to be_falsey

    sign_in(no_permission_user)
    visit company_employees_path(company)

    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)
  end

  # =========================================================================
  # SCENARIO 8: Owner can grant CRUD permissions via UI
  # =========================================================================
  scenario "owner can grant create permission to role via permissions page" do
    sign_in(owner)
    visit company_permissions_path(company)

    expect(page).to have_selector('.role-section', text: "NoPermission", wait: 20)

    no_permission_section = find('.role-section', text: "NoPermission")
    expect(no_permission_section).not_to have_selector('.resource-section', text: 'Employee')

    no_permission_section.click_button("Add Resource")

    within(".swal2-html-container") do
      select "Employee", from: "permission[resource_name]"
      click_button "Add Resource"
    end

    expect(page).to have_content("Resource added successfully", wait: 10)

    toggle_policy(role_text: "NoPermission", action: "create", resource: "Employee")

    company.clear_permissions_cache
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload

    expect(no_permission_employee.can?(:create, Employee)).to be_truthy
  end

  # =========================================================================
  # SCENARIO 9: Owner can remove permission via UI
  # =========================================================================
  scenario "owner can remove permission from role via permissions page" do
    sign_in(owner)
    visit company_permissions_path(company)

    reader_section = find('.role-section', text: "Reader")
    expect(reader_section).to have_selector('.resource-section', text: 'Employee')

    toggle_policy(role_text: "Reader", action: "read", resource: "Employee")

    company.clear_permissions_cache
    reader_employee.clear_permissions_cache
    reader_employee.reload

    expect(reader_employee.can?(:read, Employee)).to be_falsey
  end

  # =========================================================================
  # SCENARIO 10: Employee granted create permission via UI can then create
  # =========================================================================
  scenario "employee granted create permission can then create new employee" do
    sign_in(owner)
    visit company_permissions_path(company)

    no_permission_section = find('.role-section', text: "NoPermission")

    unless no_permission_section.has_selector?('.resource-section', text: 'Employee')
      no_permission_section.click_button("Add Resource")
      within(".swal2-html-container") do
        select "Employee", from: "permission[resource_name]"
        click_button "Add Resource"
      end
      expect(page).to have_content("Resource added successfully", wait: 10)
    end

    toggle_policy(role_text: "NoPermission", action: "read", resource: "Employee")
    toggle_policy(role_text: "NoPermission", action: "create", resource: "Employee")

    company.clear_permissions_cache
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload
    expect(no_permission_employee.can?(:create, Employee)).to be_truthy

    company.clear_permissions_cache
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload

    sign_in(no_permission_user)
    seed_client_cache
    visit new_company_employee_path(company)

    expect(page).to have_selector('input[name="employee[name]"]', wait: 10)
    fill_in 'employee[name]', with: 'Created After Grant'
    page.execute_script("document.querySelector('select[name=\"employee[business_type]\"]').value = 'full_time'")

    click_button "Save Employee"

    expect(page).to have_content('Created After Grant', wait: 10)

    expect(Employee.find_by(name: "Created After Grant")).to be_present
  end

  # =========================================================================
  # SCENARIO 11: Employee with create permission removed cannot create
  # =========================================================================
  scenario "employee with create permission removed cannot create new employee" do
    company.clear_permissions_cache
    creator_employee.clear_permissions_cache
    creator_employee.reload
    expect(creator_employee.can?(:create, Employee)).to be_truthy

    sign_in(owner)
    visit company_permissions_path(company)

    toggle_policy(role_text: "Creator", action: "create", resource: "Employee")

    company.clear_permissions_cache
    creator_employee.clear_permissions_cache
    creator_employee.reload
    expect(creator_employee.can?(:create, Employee)).to be_falsey

    sign_in(creator_user)
    visit new_company_employee_path(company)

    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)
    expect(Employee.find_by(name: "Should Be Rejected")).to be_nil
  end

  # =========================================================================
  # SCENARIO 12: Permission toggle off then on verifies cache clears
  # =========================================================================
  scenario "permission toggle off then on works correctly" do
    company.clear_permissions_cache
    creator_employee.clear_permissions_cache
    creator_employee.reload
    expect(creator_employee.can?(:create, Employee)).to be_truthy

    sign_in(owner)
    visit company_permissions_path(company)

    # Toggle OFF
    toggle_policy(role_text: "Creator", action: "create", resource: "Employee")

    company.clear_permissions_cache
    creator_employee.clear_permissions_cache
    creator_employee.reload
    expect(creator_employee.can?(:create, Employee)).to be_falsey

    # Toggle ON again — use direct DB update to avoid browser race
    appointment = PolicyAppointment.where(company: company, policy: policy_create_employee, appoint_to: creator_role).last!
    appointment.update!(workflow_status: :active)
    company.clear_permissions_cache
    creator_employee.clear_permissions_cache
    creator_employee.reload
    expect(creator_employee.can?(:create, Employee)).to be_truthy
  end

  # =========================================================================
  # SCENARIO 13: Owner employee bypasses all permissions
  # =========================================================================
  scenario "owner employee can access dashboard regardless of permissions" do
    sign_in(owner)
    visit company_employees_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('a', text: 'Add')
  end

  scenario "owner can? returns true for all actions (includes delete)" do
    owner_employee = company.employees.find_by(user: owner)

    expect(owner_employee.owner_role?).to be_truthy
    expect(owner_employee.can?(:read, Employee)).to be_truthy
    expect(owner_employee.can?(:create, Employee)).to be_truthy
    expect(owner_employee.can?(:update, Employee)).to be_truthy
    expect(owner_employee.can?(:delete, Employee)).to be_truthy
  end
end
