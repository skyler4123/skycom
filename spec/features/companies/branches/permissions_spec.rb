require "rails_helper"

RSpec.feature "Companies::Branches Permissions", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:owner) { company.user }

  # Roles
  let!(:reader_role) { create(:role, company: company, name: "Reader", business_type: :support) }
  let!(:creator_role) { create(:role, company: company, name: "Creator", business_type: :support) }
  let!(:editor_role) { create(:role, company: company, name: "Editor", business_type: :management) }
  let!(:no_permission_role) { create(:role, company: company, name: "NoPermission", business_type: :support) }

  # Policies for Branch resource
  let!(:policy_read_branch) { create_policy(resource: "Branch", action: "read") }
  let!(:policy_create_branch) { create_policy(resource: "Branch", action: "create") }
  let!(:policy_update_branch) { create_policy(resource: "Branch", action: "update") }

  # Reader role: Branch(read) - active
  let!(:reader_read_branch_active) do
    create_policy_appointment(role: reader_role, policy: policy_read_branch, workflow_status: :active)
  end

  # Creator role: Branch(read, create) - active
  let!(:creator_read_branch_active) do
    create_policy_appointment(role: creator_role, policy: policy_read_branch, workflow_status: :active)
  end
  let!(:creator_create_branch_active) do
    create_policy_appointment(role: creator_role, policy: policy_create_branch, workflow_status: :active)
  end

  # Editor role: Branch(read, update) - active
  let!(:editor_read_branch_active) do
    create_policy_appointment(role: editor_role, policy: policy_read_branch, workflow_status: :active)
  end
  let!(:editor_update_branch_active) do
    create_policy_appointment(role: editor_role, policy: policy_update_branch, workflow_status: :active)
  end

  # NoPermission role: NO policies for Branch

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

  # Target branch for edit tests
  let!(:target_branch) { create(:branch, company: company, name: "Target Branch") }

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

  before do
    company.clear_permissions_cache
  end

  # =========================================================================
  # SCENARIO 1: Reader with only READ permission can see dashboard
  # =========================================================================
  scenario "employee with read-only permission can access branches dashboard" do
    sign_in(reader_user)
    visit company_branches_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_content("Branch Name")
  end

  scenario "reader can? returns true for read, false for create/update" do
    reader_employee.clear_permissions_cache
    reader_employee.reload

    expect(reader_employee.can?(:read, Branch)).to be_truthy
    expect(reader_employee.can?(:create, Branch)).to be_falsey
    expect(reader_employee.can?(:update, Branch)).to be_falsey
  end

  scenario "read-only employee can see Add link in UI (UI doesn't gate on permissions)" do
    reader_employee.clear_permissions_cache
    sign_in(reader_user)
    visit company_branches_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('a', text: 'Add')
  end

  # =========================================================================
  # SCENARIO 2: Creator with READ+CREATE can create branch
  # =========================================================================
  scenario "employee with create permission can see Add link" do
    creator_employee.clear_permissions_cache
    sign_in(creator_user)
    visit company_branches_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('a', text: 'Add', wait: 5)
  end

  scenario "employee with create permission can access new page" do
    creator_employee.clear_permissions_cache
    sign_in(creator_user)
    visit new_company_branch_path(company)

    expect(page).to have_selector('input[name="branch[name]"]', wait: 10)
  end

  scenario "creator can create new branch and see in table" do
    creator_employee.clear_permissions_cache
    company.clear_permissions_cache
    creator_employee.reload

    sign_in(creator_user)
    visit new_company_branch_path(company)

    expect(page).to have_selector('input[name="branch[name]"]', wait: 10)
    fill_in 'branch[name]', with: 'Created by Creator'
    select 'Warehouse', from: 'branch[business_type]'

    click_button "Save Branch"

    expect(page).to have_content('Created by Creator', wait: 10)

    expect(Branch.find_by(name: "Created by Creator")).to be_present
  end

  scenario "creator can? returns true for read and create" do
    creator_employee.clear_permissions_cache
    creator_employee.reload

    expect(creator_employee.can?(:read, Branch)).to be_truthy
    expect(creator_employee.can?(:create, Branch)).to be_truthy
    expect(creator_employee.can?(:update, Branch)).to be_falsey
  end

  # =========================================================================
  # SCENARIO 2a: Employee WITHOUT create permission gets error when trying to create
  # =========================================================================
  scenario "employee without create permission cannot access new page" do
    sign_in(owner)
    visit company_permissions_path(company)

    no_permission_section = find('.role-section', text: "NoPermission")

    unless no_permission_section.has_content?("Can read Branch")
      no_permission_section.click_button("Add Resource")
      within(".swal2-html-container") do
        select "Branch", from: "permission[resource_name]"
        click_button "Add Resource"
      end
      expect(page).to have_content("Resource added successfully", wait: 10)
    end

    toggle_policy(role_text: "NoPermission", action: "read", resource: "Branch")

    company.clear_permissions_cache

    sign_in(no_permission_user)
    visit new_company_branch_path(company)

    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)
  end

  # =========================================================================
  # SCENARIO 3: Editor with READ+UPDATE can edit branch
  # =========================================================================
  scenario "employee with update permission can see table with edit links" do
    editor_employee.clear_permissions_cache
    sign_in(editor_user)
    visit company_branches_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('a[href*="/edit"]', minimum: 1)
  end

  scenario "editor can? returns true for read and update" do
    editor_employee.clear_permissions_cache
    editor_employee.reload

    expect(editor_employee.can?(:read, Branch)).to be_truthy
    expect(editor_employee.can?(:create, Branch)).to be_falsey
    expect(editor_employee.can?(:update, Branch)).to be_truthy
  end


  scenario "editor with update permission can update branch name via edit page" do
    editor_employee.clear_permissions_cache
    company.clear_permissions_cache
    editor_employee.reload

    sign_in(editor_user)
    visit edit_company_branch_path(company, target_branch)

    expect(page).to have_selector('input[name="branch[name]"]', wait: 10)
    fill_in 'branch[name]', with: 'Updated Branch Name'

    click_button "Save Changes"

    expect(page).to have_content('Updated Branch Name', wait: 10)
    expect(Branch.find_by(id: target_branch.id).name).to eq("Updated Branch Name")
  end

  # =========================================================================
  # SCENARIO 3d: Employee WITHOUT update permission gets error when editing
  # =========================================================================
  scenario "employee without update permission cannot access edit page" do
    sign_in(owner)
    visit company_permissions_path(company)

    editor_section = find('.role-section', text: "Editor")
    branch_section = editor_section.find('.resource-section', text: 'Branch')

    unless branch_section.has_selector?('button', text: /update/)
      editor_section.click_button("Add Resource")
      within(".swal2-html-container") do
        select "Branch", from: "permission[resource_name]"
        click_button "Add Resource"
      end
      expect(page).to have_content("Resource added successfully", wait: 10)
    end

    company.clear_permissions_cache

    # Remove update permission from editor temporarily by setting workflow_status to inactive
    appointment = PolicyAppointment.find_by(appoint_to: editor_role, policy: policy_update_branch)
    appointment.update!(workflow_status: :inactive)
    company.clear_permissions_cache
    editor_employee.reload

    expect(editor_employee.can?(:update, Branch)).to be_falsey

    # Try to access edit page - should fail with authorization error
    sign_in(editor_user)
    visit edit_company_branch_path(company, target_branch)

    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)

    target_branch.reload
    expect(target_branch.name).not_to eq("Attempted Update")
  end

  # =========================================================================
  # SCENARIO 4: Owner has all permissions bypass
  # =========================================================================
  scenario "owner can? returns true for all actions" do
    owner_employee = company.employees.find_by(user: owner)

    expect(owner_employee.can?(:read, Branch)).to be_truthy
    expect(owner_employee.can?(:create, Branch)).to be_truthy
    expect(owner_employee.can?(:update, Branch)).to be_truthy
  end

  # =========================================================================
  # SCENARIO 5: Permission changes via UI toggle work correctly
  # =========================================================================
  scenario "policy appointment workflow_status can be toggled to grant permission" do
    # NoPermission role initially has no Branch create permission
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload
    expect(no_permission_employee.can?(:create, Branch)).to be_falsey

    # Grant permission via policy appointment
    sign_in(owner)
    visit company_permissions_path(company)

    no_permission_section = find('.role-section', text: "NoPermission")

    # Add Branch resource if not present
    unless no_permission_section.has_content?("Can create Branch")
      no_permission_section.click_button("Add Resource")
      within(".swal2-html-container") do
        select "Branch", from: "permission[resource_name]"
        click_button "Add Resource"
      end
      expect(page).to have_content("Resource added successfully", wait: 10)
    end

    # Activate create permission
    toggle_policy(role_text: "NoPermission", action: "create", resource: "Branch")

    company.clear_permissions_cache
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload
    expect(no_permission_employee.can?(:create, Branch)).to be_truthy
  end

  # =========================================================================
  # SCENARIO 6: Deactivating policy appointment revokes permission
  # =========================================================================
  scenario "policy appointment workflow_status can be toggled to revoke permission" do
    # Editor role initially has Branch update permission
    editor_employee.clear_permissions_cache
    editor_employee.reload
    expect(editor_employee.can?(:update, Branch)).to be_truthy

    # Find and deactivate the update permission
    appointment = PolicyAppointment.find_by(appoint_to: editor_role, policy: policy_update_branch)
    appointment.update!(workflow_status: :inactive)
    company.clear_permissions_cache

    editor_employee.reload
    expect(editor_employee.can?(:update, Branch)).to be_falsey
  end

  # =========================================================================
  # SCENARIO 7: No permission employee cannot access branch dashboard
  # =========================================================================
  scenario "employee without read permission cannot access branches dashboard" do
    # NoPermission role has no Branch policies at all
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload

    expect(no_permission_employee.can?(:read, Branch)).to be_falsey

    sign_in(no_permission_user)
    visit company_branches_path(company)

    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)
  end
end
