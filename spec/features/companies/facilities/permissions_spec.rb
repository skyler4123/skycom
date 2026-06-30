require "rails_helper"

RSpec.feature "Companies::Facilities Permissions", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:owner) { company.user }

  # Roles
  let!(:reader_role) { create(:role, company: company, name: "Reader", business_type: :support) }
  let!(:creator_role) { create(:role, company: company, name: "Creator", business_type: :support) }
  let!(:editor_role) { create(:role, company: company, name: "Editor", business_type: :management) }
  let!(:no_permission_role) { create(:role, company: company, name: "NoPermission", business_type: :support) }

  # Policies for Facility resource
  let!(:policy_read_facility) { create_policy(resource: "Facility", action: "read") }
  let!(:policy_create_facility) { create_policy(resource: "Facility", action: "create") }
  let!(:policy_update_facility) { create_policy(resource: "Facility", action: "update") }

  # Reader role: Facility(read) - active
  let!(:reader_read_facility_active) do
    create_policy_appointment(role: reader_role, policy: policy_read_facility, workflow_status: :active)
  end

  # Creator role: Facility(read, create) - active
  let!(:creator_read_facility_active) do
    create_policy_appointment(role: creator_role, policy: policy_read_facility, workflow_status: :active)
  end
  let!(:creator_create_facility_active) do
    create_policy_appointment(role: creator_role, policy: policy_create_facility, workflow_status: :active)
  end

  # Editor role: Facility(read, update) - active
  let!(:editor_read_facility_active) do
    create_policy_appointment(role: editor_role, policy: policy_read_facility, workflow_status: :active)
  end
  let!(:editor_update_facility_active) do
    create_policy_appointment(role: editor_role, policy: policy_update_facility, workflow_status: :active)
  end

  # NoPermission role: NO policies for Facility

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

  # Target facility for edit tests
  let!(:target_facility) { create(:facility, company: company, branch: branch, name: "Target Facility") }

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
  scenario "employee with read-only permission can access facilities dashboard" do
    sign_in(reader_user)
    visit company_facilities_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_content(target_facility.name)
  end

  scenario "reader can? returns true for read, false for create/update" do
    reader_employee.clear_permissions_cache
    reader_employee.reload

    expect(reader_employee.can?(:read, Facility)).to be_truthy
    expect(reader_employee.can?(:create, Facility)).to be_falsey
    expect(reader_employee.can?(:update, Facility)).to be_falsey
  end

  scenario "read-only employee can see Add link in UI (UI doesn't gate on permissions)" do
    reader_employee.clear_permissions_cache
    sign_in(reader_user)
    visit company_facilities_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('a', text: 'Add')
  end

  # =========================================================================
  # SCENARIO 2: Creator with READ+CREATE can create facility
  # =========================================================================
  scenario "employee with create permission can see Add link" do
    creator_employee.clear_permissions_cache
    sign_in(creator_user)
    visit company_facilities_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('a', text: 'Add', wait: 5)
  end

  scenario "employee with create permission can access new facility page" do
    creator_employee.clear_permissions_cache
    sign_in(creator_user)
    visit new_company_facility_path(company)

    expect(page).to have_selector('input[name="facility[name]"]', wait: 10)
  end

  scenario "creator can create new facility and see in table" do
    creator_employee.clear_permissions_cache
    company.clear_permissions_cache
    creator_employee.reload

    sign_in(creator_user)
    visit new_company_facility_path(company)

    expect(page).to have_selector('input[name="facility[name]"]', wait: 10)
    fill_in 'facility[name]', with: 'Created by Creator'

    click_button "Save Facility"

    expect(page).to have_content('Created by Creator', wait: 10)

    expect(Facility.find_by(name: "Created by Creator")).to be_present
  end

  scenario "creator can? returns true for read and create" do
    creator_employee.clear_permissions_cache
    creator_employee.reload

    expect(creator_employee.can?(:read, Facility)).to be_truthy
    expect(creator_employee.can?(:create, Facility)).to be_truthy
    expect(creator_employee.can?(:update, Facility)).to be_falsey
  end

  # =========================================================================
  # SCENARIO 2a: Employee WITHOUT create permission gets error when trying to create
  # =========================================================================
  scenario "employee without create permission cannot access new facility page" do
    sign_in(owner)
    visit company_permissions_path(company)

    no_permission_section = find('.role-section', text: "NoPermission")

    unless no_permission_section.has_content?("Can read Facility")
      no_permission_section.click_button("Add Resource")
      within(".swal2-html-container") do
        select "Facility", from: "permission[resource_name]"
        click_button "Add Resource"
      end
      expect(page).to have_content("Resource added successfully", wait: 10)
    end

    toggle_policy(role_text: "NoPermission", action: "read", resource: "Facility")

    company.clear_permissions_cache

    sign_in(no_permission_user)
    visit new_company_facility_path(company)

    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)
  end

  # =========================================================================
  # SCENARIO 3: Editor with READ+UPDATE can edit facility
  # =========================================================================
  scenario "employee with update permission can see table with edit links" do
    editor_employee.clear_permissions_cache
    sign_in(editor_user)
    visit company_facilities_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('a[href*="/edit"]', minimum: 1)
  end

  scenario "editor can? returns true for read and update" do
    editor_employee.clear_permissions_cache
    editor_employee.reload

    expect(editor_employee.can?(:read, Facility)).to be_truthy
    expect(editor_employee.can?(:create, Facility)).to be_falsey
    expect(editor_employee.can?(:update, Facility)).to be_truthy
  end

  scenario "editor with update permission can update facility name via edit page" do
    editor_employee.clear_permissions_cache
    company.clear_permissions_cache
    editor_employee.reload

    sign_in(editor_user)
    visit edit_company_facility_path(company, target_facility)

    expect(page).to have_selector('input[name="facility[name]"]', wait: 10)
    fill_in 'facility[name]', with: 'Updated Facility Name'

    click_button "Save Changes"

    expect(page).to have_content('Updated Facility Name', wait: 10)
    expect(Facility.find_by(id: target_facility.id).name).to eq("Updated Facility Name")
  end

  # =========================================================================
  # SCENARIO 3d: Employee WITHOUT update permission gets error when editing
  # =========================================================================
  scenario "employee without update permission cannot access edit page" do
    sign_in(owner)
    visit company_permissions_path(company)

    editor_section = find('.role-section', text: "Editor")

    unless editor_section.has_content?("Facility")
      editor_section.click_button("Add Resource")
      within(".swal2-html-container") do
        select "Facility", from: "permission[resource_name]"
        click_button "Add Resource"
      end
      expect(page).to have_content("Resource added successfully", wait: 10)
    end

    company.clear_permissions_cache

    appointment = PolicyAppointment.find_by(appoint_to: editor_role, policy: policy_update_facility)
    appointment.update!(workflow_status: :inactive)
    company.clear_permissions_cache
    editor_employee.reload

    expect(editor_employee.can?(:update, Facility)).to be_falsey

    sign_in(editor_user)
    visit edit_company_facility_path(company, target_facility)

    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)

    target_facility.reload
    expect(target_facility.name).not_to eq("Attempted Update")
  end

  # =========================================================================
  # SCENARIO 4: Owner has all permissions bypass
  # =========================================================================
  scenario "owner can? returns true for all actions" do
    owner_employee = company.employees.find_by(user: owner)

    expect(owner_employee.can?(:read, Facility)).to be_truthy
    expect(owner_employee.can?(:create, Facility)).to be_truthy
    expect(owner_employee.can?(:update, Facility)).to be_truthy
  end

  # =========================================================================
  # SCENARIO 5: Permission changes via UI toggle work correctly
  # =========================================================================
  scenario "policy appointment workflow_status can be toggled to grant permission" do
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload
    expect(no_permission_employee.can?(:create, Facility)).to be_falsey

    sign_in(owner)
    visit company_permissions_path(company)

    no_permission_section = find('.role-section', text: "NoPermission")

    unless no_permission_section.has_content?("Can create Facility")
      no_permission_section.click_button("Add Resource")
      within(".swal2-html-container") do
        select "Facility", from: "permission[resource_name]"
        click_button "Add Resource"
      end
      expect(page).to have_content("Resource added successfully", wait: 10)
    end

    toggle_policy(role_text: "NoPermission", action: "create", resource: "Facility")

    company.clear_permissions_cache
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload
    expect(no_permission_employee.can?(:create, Facility)).to be_truthy
  end

  # =========================================================================
  # SCENARIO 6: Deactivating policy appointment revokes permission
  # =========================================================================
  scenario "policy appointment workflow_status can be toggled to revoke permission" do
    editor_employee.clear_permissions_cache
    editor_employee.reload
    expect(editor_employee.can?(:update, Facility)).to be_truthy

    appointment = PolicyAppointment.find_by(appoint_to: editor_role, policy: policy_update_facility)
    appointment.update!(workflow_status: :inactive)
    company.clear_permissions_cache

    editor_employee.reload
    expect(editor_employee.can?(:update, Facility)).to be_falsey
  end

  # =========================================================================
  # SCENARIO 7: No permission employee cannot access facility dashboard
  # =========================================================================
  scenario "employee without read permission cannot access facilities dashboard" do
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload

    expect(no_permission_employee.can?(:read, Facility)).to be_falsey

    sign_in(no_permission_user)
    visit company_facilities_path(company)

    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)
  end
end
