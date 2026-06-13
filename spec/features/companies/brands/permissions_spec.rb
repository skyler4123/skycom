require "rails_helper"

RSpec.feature "Companies::Brands Permissions", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:owner) { company.user }

  # Roles
  let!(:reader_role) { create(:role, company: company, name: "Reader", business_type: :support) }
  let!(:creator_role) { create(:role, company: company, name: "Creator", business_type: :support) }
  let!(:editor_role) { create(:role, company: company, name: "Editor", business_type: :management) }
  let!(:no_permission_role) { create(:role, company: company, name: "NoPermission", business_type: :support) }

  # Policies for Brand resource
  let!(:policy_read_brand) { create_policy(resource: "Brand", action: "read") }
  let!(:policy_create_brand) { create_policy(resource: "Brand", action: "create") }
  let!(:policy_update_brand) { create_policy(resource: "Brand", action: "update") }

  # Reader role: Brand(read) - active
  let!(:reader_read_brand_active) do
    create_policy_appointment(role: reader_role, policy: policy_read_brand, workflow_status: :active)
  end

  # Creator role: Brand(read, create) - active
  let!(:creator_read_brand_active) do
    create_policy_appointment(role: creator_role, policy: policy_read_brand, workflow_status: :active)
  end
  let!(:creator_create_brand_active) do
    create_policy_appointment(role: creator_role, policy: policy_create_brand, workflow_status: :active)
  end

  # Editor role: Brand(read, update) - active
  let!(:editor_read_brand_active) do
    create_policy_appointment(role: editor_role, policy: policy_read_brand, workflow_status: :active)
  end
  let!(:editor_update_brand_active) do
    create_policy_appointment(role: editor_role, policy: policy_update_brand, workflow_status: :active)
  end

  # NoPermission role: NO policies for Brand

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

  # Target brand for edit tests
  let!(:target_brand) { create(:brand, company: company, name: "Target Brand") }

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
  scenario "employee with read-only permission can access brands dashboard" do
    sign_in(reader_user)
    visit company_brands_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_content("Brand Name")
  end

  scenario "reader can? returns true for read, false for create/update" do
    reader_employee.clear_permissions_cache
    reader_employee.reload

    expect(reader_employee.can?(:read, Brand)).to be_truthy
    expect(reader_employee.can?(:create, Brand)).to be_falsey
    expect(reader_employee.can?(:update, Brand)).to be_falsey
  end

  scenario "read-only employee can see Add link in UI (UI doesn't gate on permissions)" do
    reader_employee.clear_permissions_cache
    sign_in(reader_user)
    visit company_brands_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('a', text: 'Add')
  end

  # =========================================================================
  # SCENARIO 2: Creator with READ+CREATE can create brand
  # =========================================================================
  scenario "employee with create permission can see Add link" do
    creator_employee.clear_permissions_cache
    sign_in(creator_user)
    visit company_brands_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('a', text: 'Add', wait: 5)
  end

  scenario "employee with create permission can access new page" do
    creator_employee.clear_permissions_cache
    sign_in(creator_user)
    visit new_company_brand_path(company)

    expect(page).to have_selector('input[name="brand[name]"]', wait: 10)
  end

  scenario "creator can create new brand and see in table" do
    creator_employee.clear_permissions_cache
    company.clear_permissions_cache
    creator_employee.reload

    sign_in(creator_user)
    visit new_company_brand_path(company)

    expect(page).to have_selector('input[name="brand[name]"]', wait: 10)
    fill_in 'brand[name]', with: 'Created by Creator'
    select 'Manufacturer', from: 'brand[business_type]'

    click_button "Save Brand"

    expect(page).to have_content('Created by Creator', wait: 10)

    expect(Brand.find_by(name: "Created by Creator")).to be_present
  end

  scenario "creator can? returns true for read and create" do
    creator_employee.clear_permissions_cache
    creator_employee.reload

    expect(creator_employee.can?(:read, Brand)).to be_truthy
    expect(creator_employee.can?(:create, Brand)).to be_truthy
    expect(creator_employee.can?(:update, Brand)).to be_falsey
  end

  # =========================================================================
  # SCENARIO 2a: Employee WITHOUT create permission gets error when trying to create
  # =========================================================================
  scenario "employee without create permission cannot access new page" do
    sign_in(owner)
    visit company_permissions_path(company)

    no_permission_section = find('.role-section', text: "NoPermission")

    unless no_permission_section.has_content?("Can read Brand")
      no_permission_section.click_button("Add Resource")
      within(".swal2-html-container") do
        select "Brand", from: "permission[resource_name]"
        click_button "Add Resource"
      end
      expect(page).to have_content("Resource added successfully", wait: 10)
    end

    no_permission_section = find('.role-section', text: "NoPermission")
    read_label = no_permission_section.all('label').find { |l| l.text.include?("Can read Brand") }
    read_checkbox = read_label.find('input[type="checkbox"]')

    unless read_checkbox.checked?
      accept_confirm do
        read_checkbox.click
      end
      expect(page).to have_selector('input[type="checkbox"]:checked', wait: 10)
    end

    company.clear_permissions_cache

    sign_in(no_permission_user)
    visit new_company_brand_path(company)

    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)
  end

  # =========================================================================
  # SCENARIO 3: Editor with READ+UPDATE can edit brand
  # =========================================================================
  scenario "employee with update permission can see table with edit links" do
    editor_employee.clear_permissions_cache
    sign_in(editor_user)
    visit company_brands_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('a[href*="/edit"]', minimum: 1)
  end

  scenario "editor can? returns true for read and update" do
    editor_employee.clear_permissions_cache
    editor_employee.reload

    expect(editor_employee.can?(:read, Brand)).to be_truthy
    expect(editor_employee.can?(:create, Brand)).to be_falsey
    expect(editor_employee.can?(:update, Brand)).to be_truthy
  end

  scenario "editor with update permission can update brand name via edit page" do
    editor_employee.clear_permissions_cache
    company.clear_permissions_cache
    editor_employee.reload

    sign_in(editor_user)
    visit edit_company_brand_path(company, target_brand)

    expect(page).to have_selector('input[name="brand[name]"]', wait: 10)
    fill_in 'brand[name]', with: 'Updated Brand Name'

    click_button "Save Changes"

    expect(page).to have_content('Updated Brand Name', wait: 10)
    expect(Brand.find_by(id: target_brand.id).name).to eq("Updated Brand Name")
  end

  # =========================================================================
  # SCENARIO 3d: Employee WITHOUT update permission gets error when editing
  # =========================================================================
  scenario "employee without update permission cannot access edit page" do
    sign_in(owner)
    visit company_permissions_path(company)

    editor_section = find('.role-section', text: "Editor")

    unless editor_section.has_content?("Can update Brand")
      editor_section.click_button("Add Resource")
      within(".swal2-html-container") do
        select "Brand", from: "permission[resource_name]"
        click_button "Add Resource"
      end
      expect(page).to have_content("Resource added successfully", wait: 10)
    end

    company.clear_permissions_cache

    # Remove update permission from editor temporarily
    appointment = PolicyAppointment.find_by(appoint_to: editor_role, policy: policy_update_brand)
    appointment.update!(workflow_status: :inactive)
    company.clear_permissions_cache
    editor_employee.reload

    expect(editor_employee.can?(:update, Brand)).to be_falsey

    sign_in(editor_user)
    visit edit_company_brand_path(company, target_brand)

    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)

    target_brand.reload
    expect(target_brand.name).not_to eq("Attempted Update")
  end

  # =========================================================================
  # SCENARIO 4: Owner has all permissions bypass
  # =========================================================================
  scenario "owner can? returns true for all actions" do
    owner_employee = company.employees.find_by(user: owner)

    expect(owner_employee.can?(:read, Brand)).to be_truthy
    expect(owner_employee.can?(:create, Brand)).to be_truthy
    expect(owner_employee.can?(:update, Brand)).to be_truthy
  end

  # =========================================================================
  # SCENARIO 5: Permission changes via UI toggle work correctly
  # =========================================================================
  scenario "policy appointment workflow_status can be toggled to grant permission" do
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload
    expect(no_permission_employee.can?(:create, Brand)).to be_falsey

    sign_in(owner)
    visit company_permissions_path(company)

    no_permission_section = find('.role-section', text: "NoPermission")

    unless no_permission_section.has_content?("Can create Brand")
      no_permission_section.click_button("Add Resource")
      within(".swal2-html-container") do
        select "Brand", from: "permission[resource_name]"
        click_button "Add Resource"
      end
      expect(page).to have_content("Resource added successfully", wait: 10)
    end

    no_permission_section = find('.role-section', text: "NoPermission")
    create_label = no_permission_section.all('label').find { |l| l.text.include?("Can create Brand") }

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
    expect(no_permission_employee.can?(:create, Brand)).to be_truthy
  end

  # =========================================================================
  # SCENARIO 6: Deactivating policy appointment revokes permission
  # =========================================================================
  scenario "policy appointment workflow_status can be toggled to revoke permission" do
    editor_employee.clear_permissions_cache
    editor_employee.reload
    expect(editor_employee.can?(:update, Brand)).to be_truthy

    appointment = PolicyAppointment.find_by(appoint_to: editor_role, policy: policy_update_brand)
    appointment.update!(workflow_status: :inactive)
    company.clear_permissions_cache

    editor_employee.reload
    expect(editor_employee.can?(:update, Brand)).to be_falsey
  end

  # =========================================================================
  # SCENARIO 7: No permission employee cannot access brand dashboard
  # =========================================================================
  scenario "employee without read permission cannot access brands dashboard" do
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload

    expect(no_permission_employee.can?(:read, Brand)).to be_falsey

    sign_in(no_permission_user)
    visit company_brands_path(company)

    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)
  end
end
