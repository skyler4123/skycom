require "rails_helper"

RSpec.feature "Companies::Employees Permissions", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:owner) { company.user }

  # Roles
  let!(:reader_role) { create(:role, company: company, name: "Reader", role_business_type: :support) }
  let!(:creator_role) { create(:role, company: company, name: "Creator", role_business_type: :support) }
  let!(:editor_role) { create(:role, company: company, name: "Editor", role_business_type: :management) }
  let!(:no_permission_role) { create(:role, company: company, name: "NoPermission", role_business_type: :support) }

  # Policies for Employee resource
  let!(:policy_read_employee) { create_policy(resource: "Employee", action: "read") }
  let!(:policy_create_employee) { create_policy(resource: "Employee", action: "create") }
  let!(:policy_update_employee) { create_policy(resource: "Employee", action: "update") }
  let!(:policy_delete_employee) { create_policy(resource: "Employee", action: "delete") }

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
    create(:employee, company: company, branch: branch, user: reader_user, roles: [ reader_role ]).tap do
      company.clear_permissions_cache
    end
  end

  let!(:creator_user) { create(:user, :company_employee) }
  let!(:creator_employee) do
    create(:employee, company: company, branch: branch, user: creator_user, roles: [ creator_role ])
  end

  let!(:editor_user) { create(:user, :company_employee) }
  let!(:editor_employee) do
    create(:employee, company: company, branch: branch, user: editor_user, roles: [ editor_role ])
  end

  let!(:no_permission_user) { create(:user, :company_employee) }
  let!(:no_permission_employee) do
    create(:employee, company: company, branch: branch, user: no_permission_user, roles: [ no_permission_role ])
  end

  # Target employee for edit/delete tests
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

  scenario "reader can? returns true for read, false for create/update/delete" do
    reader_employee.clear_permissions_cache
    reader_employee.reload

    expect(reader_employee.can?(:read, Employee)).to be_truthy
    expect(reader_employee.can?(:create, Employee)).to be_falsey
    expect(reader_employee.can?(:update, Employee)).to be_falsey
    expect(reader_employee.can?(:delete, Employee)).to be_falsey
  end

  # Note: The UI currently doesn't hide buttons based on permissions
  # This is a backend permission check only scenario
  scenario "read-only employee can see Add button in UI (UI doesn't gate on permissions)" do
    reader_employee.clear_permissions_cache
    sign_in(reader_user)
    visit company_employees_path(company)

    # Currently the UI shows all buttons regardless of permissions
    # The permission gate happens at the backend level when submitting
    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('button', text: 'Add')
  end

  # =========================================================================
  # SCENARIO 2: Creator with READ+CREATE can create employee
  # =========================================================================
  scenario "employee with create permission can see Add button" do
    creator_employee.clear_permissions_cache
    sign_in(creator_user)
    visit company_employees_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('button', text: 'Add', wait: 5)
  end

  scenario "employee with create permission can open create modal" do
    creator_employee.clear_permissions_cache
    sign_in(creator_user)
    visit company_employees_path(company)

    expect(page).to have_selector('[data-action*="openNewModal"]', wait: 5)
    find('[data-action*="openNewModal"]').click
    expect(page).to have_selector('form[data-action*="handleSubmit"]', wait: 10)
  end

  scenario "creator can create new employee and see in table" do
    creator_employee.clear_permissions_cache
    sign_in(creator_user)
    visit company_employees_path(company)

    find('[data-action*="openNewModal"]').click

    expect(page).to have_selector('form[data-action*="handleSubmit"]', wait: 10)
    expect(page).to have_selector('input[name="employee[name]"]', wait: 5)
    fill_in 'employee[name]', with: 'Created by Creator'
    select 'Full Time', from: 'employee[business_type]'

    click_button "Save Employee"
    expect(page).to have_selector('tbody tr', wait: 10)

    expect(Employee.find_by(name: "Created by Creator")).to be_present
  end

  scenario "creator can? returns true for read and create" do
    creator_employee.clear_permissions_cache
    creator_employee.reload

    expect(creator_employee.can?(:read, Employee)).to be_truthy
    expect(creator_employee.can?(:create, Employee)).to be_truthy
    expect(creator_employee.can?(:update, Employee)).to be_falsey
    expect(creator_employee.can?(:delete, Employee)).to be_falsey
  end

  # =========================================================================
  # SCENARIO 3: Editor with READ+UPDATE can edit employee
  # =========================================================================
  # Note: Currently the UI shows edit buttons regardless of permissions
  # The permission gate happens at the backend when submitting
  scenario "employee with update permission can see table with edit buttons" do
    editor_employee.clear_permissions_cache
    sign_in(editor_user)
    visit company_employees_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('[data-action*="openShowModal"]', minimum: 1)
  end

  scenario "editor can? returns true for read and update" do
    editor_employee.clear_permissions_cache
    editor_employee.reload

    expect(editor_employee.can?(:read, Employee)).to be_truthy
    expect(editor_employee.can?(:create, Employee)).to be_falsey
    expect(editor_employee.can?(:update, Employee)).to be_truthy
    expect(editor_employee.can?(:delete, Employee)).to be_falsey
  end

  # =========================================================================
  # SCENARIO 4: Employee with DELETE permission can delete
  # =========================================================================
  scenario "employee with delete permission can? returns true for delete" do
    # Create a new role with delete permission - reuse existing policy
    delete_role = create(:role, company: company, name: "DeleterTest", role_business_type: :management)

    create_policy_appointment(role: delete_role, policy: policy_read_employee, workflow_status: :active)
    create_policy_appointment(role: delete_role, policy: policy_delete_employee, workflow_status: :active)

    delete_user = create(:user, :company_employee)
    delete_emp = create(:employee, company: company, branch: branch, user: delete_user, roles: [ delete_role ])

    delete_emp.clear_permissions_cache
    delete_emp.reload

    expect(delete_emp.can?(:delete, Employee)).to be_truthy
  end

  # =========================================================================
  # SCENARIO 5: Employee without permissions - backend check
  # =========================================================================
  # Note: Currently the UI shows access to everyone who can sign in
  # The can? method would return false for actions
  scenario "no permission employee can? returns false for all actions" do
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload

    expect(no_permission_employee.can?(:read, Employee)).to be_falsey
    expect(no_permission_employee.can?(:create, Employee)).to be_falsey
    expect(no_permission_employee.can?(:update, Employee)).to be_falsey
    expect(no_permission_employee.can?(:delete, Employee)).to be_falsey
  end

  # =========================================================================
  # SCENARIO 6: Owner grants CRUD permission via UI
  # =========================================================================
  scenario "owner can grant create permission to role via permissions page" do
    sign_in(owner)
    visit company_permissions_path(company)

    expect(page).to have_selector('.role-section', text: "NoPermission", wait: 20)

    no_permission_section = find('.role-section', text: "NoPermission")
    expect(no_permission_section).not_to have_content("Can create Employee")

    # Add Employee resource to this role (adds the resource with all actions inactive)
    no_permission_section.click_button("Add Resource")

    within(".swal2-html-container") do
      select "Employee", from: "permission[resource_name]"
      click_button "Add Resource"
    end

    expect(page).to have_content("Resource added successfully", wait: 10)

    # Now check the create checkbox to activate it
    no_permission_section = find('.role-section', text: "NoPermission")
    create_label = no_permission_section.all('label').find { |l| l.text.include?("Can create Employee") }
    create_checkbox = create_label.find('input[type="checkbox"]')

    accept_confirm do
      create_checkbox.click
    end

    expect(page).to have_selector('input[type="checkbox"]:checked', wait: 10)

    company.clear_permissions_cache
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload

    expect(no_permission_employee.can?(:create, Employee)).to be_truthy
  end

  scenario "owner can grant read permission to role via permissions page" do
    sign_in(owner)
    visit company_permissions_path(company)

    no_permission_section = find('.role-section', text: "NoPermission")

    # Add Employee resource
    no_permission_section.click_button("Add Resource")
    within(".swal2-html-container") do
      select "Employee", from: "permission[resource_name]"
      click_button "Add Resource"
    end
    expect(page).to have_content("Resource added successfully", wait: 10)

    # Check the read checkbox
    no_permission_section = find('.role-section', text: "NoPermission")
    read_label = no_permission_section.all('label').find { |l| l.text.include?("Can read Employee") }
    read_checkbox = read_label.find('input[type="checkbox"]')

    accept_confirm do
      read_checkbox.click
    end

    expect(page).to have_selector('input[type="checkbox"]:checked', wait: 10)

    company.clear_permissions_cache
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload

    expect(no_permission_employee.can?(:read, Employee)).to be_truthy
  end

  scenario "owner can grant update permission to role via permissions page" do
    sign_in(owner)
    visit company_permissions_path(company)

    no_permission_section = find('.role-section', text: "NoPermission")

    # Add Employee resource
    no_permission_section.click_button("Add Resource")
    within(".swal2-html-container") do
      select "Employee", from: "permission[resource_name]"
      click_button "Add Resource"
    end
    expect(page).to have_content("Resource added successfully", wait: 10)

    # Check the update checkbox
    no_permission_section = find('.role-section', text: "NoPermission")
    update_label = no_permission_section.all('label').find { |l| l.text.include?("Can update Employee") }
    update_checkbox = update_label.find('input[type="checkbox"]')

    accept_confirm do
      update_checkbox.click
    end

    expect(page).to have_selector('input[type="checkbox"]:checked', wait: 10)

    company.clear_permissions_cache
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload

    expect(no_permission_employee.can?(:update, Employee)).to be_truthy
  end

  scenario "owner can grant delete permission to role via permissions page" do
    sign_in(owner)
    visit company_permissions_path(company)

    no_permission_section = find('.role-section', text: "NoPermission")

    # Add Employee resource
    no_permission_section.click_button("Add Resource")
    within(".swal2-html-container") do
      select "Employee", from: "permission[resource_name]"
      click_button "Add Resource"
    end
    expect(page).to have_content("Resource added successfully", wait: 10)

    # Check the delete checkbox
    no_permission_section = find('.role-section', text: "NoPermission")
    delete_label = no_permission_section.all('label').find { |l| l.text.include?("Can delete Employee") }
    delete_checkbox = delete_label.find('input[type="checkbox"]')

    accept_confirm do
      delete_checkbox.click
    end

    expect(page).to have_selector('input[type="checkbox"]:checked', wait: 10)

    company.clear_permissions_cache
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload

    expect(no_permission_employee.can?(:delete, Employee)).to be_truthy
  end

  # =========================================================================
  # SCENARIO 7: Owner removes CRUD permission via UI
  # =========================================================================
  scenario "owner can remove permission from role via permissions page" do
    sign_in(owner)
    visit company_permissions_path(company)

    reader_section = find('.role-section', text: "Reader")
    expect(reader_section).to have_content("Can read Employee")

    read_label = reader_section.all('label').find { |l| l.text.include?("Can read Employee") }
    read_checkbox = read_label.find('input[type="checkbox"]')

    if read_checkbox.checked?
      accept_confirm do
        read_checkbox.click
      end

      expect(page).to have_selector('input[type="checkbox"]:not(:checked)', wait: 10)
    end

    company.clear_permissions_cache
    reader_employee.clear_permissions_cache
    reader_employee.reload

    expect(reader_employee.can?(:read, Employee)).to be_falsey
  end

  scenario "owner can remove update permission from role via permissions page" do
    # First grant update permission using editor role
    sign_in(owner)
    visit company_permissions_path(company)

    editor_section = find('.role-section', text: "Editor")
    expect(editor_section).to have_content("Can update Employee")

    update_label = editor_section.all('label').find { |l| l.text.include?("Can update Employee") }
    update_checkbox = update_label.find('input[type="checkbox"]')

    if update_checkbox.checked?
      accept_confirm do
        update_checkbox.click
      end

      expect(page).to have_selector('input[type="checkbox"]:not(:checked)', wait: 10)
    end

    company.clear_permissions_cache
    editor_employee.clear_permissions_cache
    editor_employee.reload

    expect(editor_employee.can?(:update, Employee)).to be_falsey
  end

  scenario "owner can remove delete permission from role via permissions page" do
    # First grant delete permission (create a role with delete)
    delete_role = create(:role, company: company, name: "DeleterPerm", role_business_type: :management)
    create_policy_appointment(role: delete_role, policy: policy_read_employee, workflow_status: :active)
    create_policy_appointment(role: delete_role, policy: policy_delete_employee, workflow_status: :active)

    delete_user = create(:user, :company_employee)
    delete_emp = create(:employee, company: company, branch: branch, user: delete_user, roles: [ delete_role ])

    company.clear_permissions_cache
    delete_emp.clear_permissions_cache

    sign_in(owner)
    visit company_permissions_path(company)

    deleter_section = find('.role-section', text: "DeleterPerm")
    expect(deleter_section).to have_content("Can delete Employee")

    delete_label = deleter_section.all('label').find { |l| l.text.include?("Can delete Employee") }
    delete_checkbox = delete_label.find('input[type="checkbox"]')

    if delete_checkbox.checked?
      accept_confirm do
        delete_checkbox.click
      end

      expect(page).to have_selector('input[type="checkbox"]:not(:checked)', wait: 10)
    end

    company.clear_permissions_cache
    delete_emp.clear_permissions_cache
    delete_emp.reload

    expect(delete_emp.can?(:delete, Employee)).to be_falsey
  end

  # Note: UI shows page to all employees - the permission check happens at backend
  scenario "UI still accessible after permission removal (UI doesn't gate)" do
    sign_in(owner)
    visit company_permissions_path(company)

    reader_section = find('.role-section', text: "Reader")
    read_label = reader_section.all('label').find { |l| l.text.include?("Can read Employee") }
    read_checkbox = read_label.find('input[type="checkbox"]')

    if read_checkbox.checked?
      accept_confirm do
        read_checkbox.click
      end

      expect(page).to have_selector('input[type="checkbox"]:not(:checked)', wait: 10)
    end

    company.clear_permissions_cache
    reader_employee.clear_permissions_cache

    # UI doesn't gate - employee can still see the page
    sign_in(reader_user)
    visit company_employees_path(company)

    # The UI is accessible but backend would reject actions
    expect(page).to have_selector('table', wait: 10)
  end

  # =========================================================================
  # SCENARIO 8: Owner employee bypasses all permissions
  # =========================================================================
  scenario "owner employee can access dashboard regardless of permissions" do
    # Even with no policies, owner can access
    sign_in(owner)
    visit company_employees_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('button', text: 'Add')
  end

  scenario "owner can? returns true for all actions" do
    owner_employee = company.employees.find_by(user: owner)

    expect(owner_employee.owner_role?).to be_truthy
    expect(owner_employee.can?(:read, Employee)).to be_truthy
    expect(owner_employee.can?(:create, Employee)).to be_truthy
    expect(owner_employee.can?(:update, Employee)).to be_truthy
    expect(owner_employee.can?(:delete, Employee)).to be_truthy
  end
end
