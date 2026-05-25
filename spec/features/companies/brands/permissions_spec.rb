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

  # Target brand for update tests
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

  # =========================================================================
  # SCENARIO 2: Creator with READ+CREATE can create brand
  # =========================================================================
  scenario "employee with create permission can see Add button" do
    creator_employee.clear_permissions_cache
    sign_in(creator_user)
    visit company_brands_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('button', text: 'Add', wait: 5)
  end

  scenario "employee with create permission can open create modal" do
    creator_employee.clear_permissions_cache
    sign_in(creator_user)
    visit company_brands_path(company)

    expect(page).to have_selector('[data-action*="openNewModal"]', wait: 5)
    find('[data-action*="openNewModal"]').click
    expect(page).to have_selector('form[data-action*="handleSubmit"]', wait: 10)
  end

  scenario "creator can create new brand and see in table" do
    creator_employee.clear_permissions_cache
    company.clear_permissions_cache
    creator_employee.reload

    sign_in(creator_user)
    visit company_brands_path(company)

    find('[data-action*="openNewModal"]').click

    expect(page).to have_selector('form[data-action*="handleSubmit"]', wait: 10)
    expect(page).to have_selector('input[name="brand[name]"]', wait: 5)
    fill_in 'brand[name]', with: 'Created by Creator'
    select 'Manufacturer', from: 'brand[business_type]'

    click_button "Save Brand"

    expect(page).to have_selector('tbody tr', wait: 10)
    expect(page).to have_content("Created by Creator")
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
  # SCENARIO 2a: Employee WITHOUT create permission gets error
  # =========================================================================
  scenario "employee without create permission cannot create new brand" do
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
    visit company_brands_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('[data-action*="openNewModal"]', wait: 5)

    find('[data-action*="openNewModal"]').click

    expect(page).to have_selector('form[data-action*="handleSubmit"]', wait: 10)
    fill_in 'brand[name]', with: 'Should Not Be Created'
    select 'Manufacturer', from: 'brand[business_type]'

    click_button "Save Brand"

    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)

    expect(Brand.find_by(name: "Should Not Be Created")).to be_nil
  end

  # =========================================================================
  # SCENARIO 3: Editor with READ+UPDATE can update brand
  # =========================================================================
  scenario "employee with update permission can see table with edit buttons" do
    editor_employee.clear_permissions_cache
    sign_in(editor_user)
    visit company_brands_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('[data-action*="openShowModal"]', minimum: 1)
  end

  scenario "editor can? returns true for read and update" do
    editor_employee.clear_permissions_cache
    editor_employee.reload

    expect(editor_employee.can?(:read, Brand)).to be_truthy
    expect(editor_employee.can?(:create, Brand)).to be_falsey
    expect(editor_employee.can?(:update, Brand)).to be_truthy
  end

  scenario "employee with update permission can open show modal and see form" do
    editor_employee.clear_permissions_cache
    company.clear_permissions_cache
    editor_employee.reload

    expect(editor_employee.can?(:update, Brand)).to be_truthy

    sign_in(editor_user)
    visit company_brands_path(company)

    expect(page).to have_selector('table', wait: 10)

    target_row = find('tbody tr', text: target_brand.name)
    target_row.find('[data-action*="openShowModal"]').click

    expect(page).to have_selector('.swal2-container', wait: 10)
    expect(page).to have_selector('input[name="brand[name]"]', wait: 5)
  end

  # =========================================================================
  # SCENARIO 4: Employee without permissions - backend check
  # =========================================================================
  scenario "no permission employee can? returns false for all actions" do
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload

    expect(no_permission_employee.can?(:read, Brand)).to be_falsey
    expect(no_permission_employee.can?(:create, Brand)).to be_falsey
    expect(no_permission_employee.can?(:update, Brand)).to be_falsey
  end

  # =========================================================================
  # SCENARIO 5: Owner grants CRUD permission via UI
  # =========================================================================
  scenario "owner can grant read permission to role via permissions page" do
    sign_in(owner)
    visit company_permissions_path(company)

    no_permission_section = find('.role-section', text: "NoPermission")

    no_permission_section.click_button("Add Resource")
    within(".swal2-html-container") do
      select "Brand", from: "permission[resource_name]"
      click_button "Add Resource"
    end
    expect(page).to have_content("Resource added successfully", wait: 10)

    no_permission_section = find('.role-section', text: "NoPermission")
    read_label = no_permission_section.all('label').find { |l| l.text.include?("Can read Brand") }
    read_checkbox = read_label.find('input[type="checkbox"]')

    accept_confirm do
      read_checkbox.click
    end

    expect(page).to have_selector('input[type="checkbox"]:checked', wait: 10)

    company.clear_permissions_cache
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload

    expect(no_permission_employee.can?(:read, Brand)).to be_truthy
  end

  scenario "owner can grant create permission to role via permissions page" do
    sign_in(owner)
    visit company_permissions_path(company)

    no_permission_section = find('.role-section', text: "NoPermission")

    no_permission_section.click_button("Add Resource")
    within(".swal2-html-container") do
      select "Brand", from: "permission[resource_name]"
      click_button "Add Resource"
    end
    expect(page).to have_content("Resource added successfully", wait: 10)

    no_permission_section = find('.role-section', text: "NoPermission")
    create_label = no_permission_section.all('label').find { |l| l.text.include?("Can create Brand") }
    create_checkbox = create_label.find('input[type="checkbox"]')

    accept_confirm do
      create_checkbox.click
    end

    expect(page).to have_selector('input[type="checkbox"]:checked', wait: 10)

    company.clear_permissions_cache
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload

    expect(no_permission_employee.can?(:create, Brand)).to be_truthy
  end

  scenario "owner can grant update permission to role via permissions page" do
    sign_in(owner)
    visit company_permissions_path(company)

    no_permission_section = find('.role-section', text: "NoPermission")

    no_permission_section.click_button("Add Resource")
    within(".swal2-html-container") do
      select "Brand", from: "permission[resource_name]"
      click_button "Add Resource"
    end
    expect(page).to have_content("Resource added successfully", wait: 10)

    no_permission_section = find('.role-section', text: "NoPermission")
    update_label = no_permission_section.all('label').find { |l| l.text.include?("Can update Brand") }
    update_checkbox = update_label.find('input[type="checkbox"]')

    accept_confirm do
      update_checkbox.click
    end

    expect(page).to have_selector('input[type="checkbox"]:checked', wait: 10)

    company.clear_permissions_cache
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload

    expect(no_permission_employee.can?(:update, Brand)).to be_truthy
  end

  # =========================================================================
  # SCENARIO 6: Owner removes CRUD permission via UI
  # =========================================================================
  scenario "owner can remove read permission from role via permissions page" do
    sign_in(owner)
    visit company_permissions_path(company)

    reader_section = find('.role-section', text: "Reader")
    expect(reader_section).to have_content("Can read Brand")

    read_label = reader_section.all('label').find { |l| l.text.include?("Can read Brand") }
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

    expect(reader_employee.can?(:read, Brand)).to be_falsey
  end

  scenario "owner can remove update permission from role via permissions page" do
    sign_in(owner)
    visit company_permissions_path(company)

    editor_section = find('.role-section', text: "Editor")
    expect(editor_section).to have_content("Can update Brand")

    update_label = editor_section.all('label').find { |l| l.text.include?("Can update Brand") }
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

    expect(editor_employee.can?(:update, Brand)).to be_falsey
  end

  # =========================================================================
  # SCENARIO 7: Employee redirected after permission removal
  # =========================================================================
  scenario "reader is redirected after permission removal" do
    sign_in(owner)
    visit company_permissions_path(company)

    reader_section = find('.role-section', text: "Reader")
    read_label = reader_section.all('label').find { |l| l.text.include?("Can read Brand") }
    read_checkbox = read_label.find('input[type="checkbox"]')

    if read_checkbox.checked?
      accept_confirm do
        read_checkbox.click
      end

      expect(page).to have_selector('input[type="checkbox"]:not(:checked)', wait: 10)
    end

    company.clear_permissions_cache
    reader_employee.clear_permissions_cache

    sign_in(reader_user)
    visit company_brands_path(company)

    expect(page).not_to have_selector('table')
    expect(page).to have_content("You are not authorized to perform this action.")
  end

  # =========================================================================
  # SCENARIO 8: Owner employee bypasses all permissions
  # =========================================================================
  scenario "owner employee can access dashboard regardless of permissions" do
    sign_in(owner)
    visit company_brands_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('button', text: 'Add')
  end

  scenario "owner can? returns true for all actions" do
    owner_employee = company.employees.find_by(user: owner)

    expect(owner_employee.owner_role?).to be_truthy
    expect(owner_employee.can?(:read, Brand)).to be_truthy
    expect(owner_employee.can?(:create, Brand)).to be_truthy
    expect(owner_employee.can?(:update, Brand)).to be_truthy
  end

  # =========================================================================
  # SCENARIO 9: Permission toggle OFF then ON
  # =========================================================================
  scenario "permission toggle off then on works correctly" do
    sign_in(owner)
    visit company_permissions_path(company)

    no_permission_section = find('.role-section', text: "NoPermission")

    no_permission_section.click_button("Add Resource")
    within(".swal2-html-container") do
      select "Brand", from: "permission[resource_name]"
      click_button "Add Resource"
    end
    expect(page).to have_content("Resource added successfully", wait: 10)

    no_permission_section = find('.role-section', text: "NoPermission")
    %w[read create].each do |action|
      label = no_permission_section.all('label').find { |l| l.text.include?("Can #{action} Brand") }
      checkbox = label&.find('input[type="checkbox"]')
      next unless checkbox && !checkbox.checked?
      accept_confirm do
        checkbox.click
      end
      expect(page).to have_selector('input[type="checkbox"]:checked', wait: 10)
    end

    company.clear_permissions_cache
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload
    expect(no_permission_employee.can?(:create, Brand)).to be_truthy

    # Toggle OFF
    no_permission_section = find('.role-section', text: "NoPermission")
    create_label = no_permission_section.all('label').find { |l| l.text.include?("Can create Brand") }
    create_checkbox = create_label.find('input[type="checkbox"]')

    accept_confirm do
      create_checkbox.click
    end
    expect(page).to have_selector('input[type="checkbox"]:not(:checked)', wait: 10)

    company.clear_permissions_cache
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload
    expect(no_permission_employee.can?(:create, Brand)).to be_falsey

    # Toggle ON again
    create_checkbox.reload
    accept_confirm do
      create_checkbox.click
    end
    expect(page).to have_selector('input[type="checkbox"]:checked', wait: 10)

    company.clear_permissions_cache
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload
    expect(no_permission_employee.can?(:create, Brand)).to be_truthy
  end
end
