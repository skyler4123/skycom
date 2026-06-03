require "rails_helper"

RSpec.feature "Companies::Categories Permissions", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:owner) { company.user }

  # Roles
  let!(:reader_role) { create(:role, company: company, name: "Reader", business_type: :support) }
  let!(:creator_role) { create(:role, company: company, name: "Creator", business_type: :support) }
  let!(:editor_role) { create(:role, company: company, name: "Editor", business_type: :management) }
  let!(:no_permission_role) { create(:role, company: company, name: "NoPermission", business_type: :support) }

  # Policies
  let!(:policy_read_category) { create_policy(resource: "Category", action: "read") }
  let!(:policy_create_category) { create_policy(resource: "Category", action: "create") }
  let!(:policy_update_category) { create_policy(resource: "Category", action: "update") }
  # Reader role: Category(read) - active
  let!(:reader_read_category_active) do
    create_policy_appointment(role: reader_role, policy: policy_read_category, workflow_status: :active)
  end

  # Creator role: Category(read, create) - active
  let!(:creator_read_category_active) do
    create_policy_appointment(role: creator_role, policy: policy_read_category, workflow_status: :active)
  end
  let!(:creator_create_category_active) do
    create_policy_appointment(role: creator_role, policy: policy_create_category, workflow_status: :active)
  end

  # Editor role: Category(read, update) - active
  let!(:editor_read_category_active) do
    create_policy_appointment(role: editor_role, policy: policy_read_category, workflow_status: :active)
  end
  let!(:editor_update_category_active) do
    create_policy_appointment(role: editor_role, policy: policy_update_category, workflow_status: :active)
  end

  # Test employees
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

  # Target category for edit tests
  let!(:target_category) do
    create(:category, company: company, name: "Test Category", resource_name: "products")
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

  before do
    company.clear_permissions_cache
  end

  # =========================================================================
  # SCENARIO 1: Reader with only READ permission
  # =========================================================================
  scenario "employee with read-only permission can access categories dashboard" do
    sign_in(reader_user)
    visit company_categories_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_content("Name")
  end

  scenario "reader can? returns true for read, false for create/update" do
    reader_employee.clear_permissions_cache
    reader_employee.reload

    expect(reader_employee.can?(:read, Category)).to be_truthy
    expect(reader_employee.can?(:create, Category)).to be_falsey
    expect(reader_employee.can?(:update, Category)).to be_falsey
  end

  # =========================================================================
  # SCENARIO 2: Creator with READ+CREATE
  # =========================================================================
  scenario "employee with create permission can create category" do
    creator_employee.clear_permissions_cache
    company.clear_permissions_cache
    creator_employee.reload

    sign_in(creator_user)
    visit company_categories_path(company)

    expect(page).to have_selector('table', wait: 10)

    find('[data-action*="openNewModal"]').click

    expect(page).to have_selector('form[data-action*="handleSubmit"]', wait: 10)
    fill_in 'category[name]', with: 'Created by Creator'
    select 'Products', from: 'category[resource_name]'

    click_button "Save Category"

    expect(page).to have_content("created successfully!", wait: 10)
    expect(page).to have_selector('tbody tr', wait: 10)

    expect(Category.find_by(name: "Created by Creator")).to be_present
  end

  scenario "creator can? returns true for read and create" do
    creator_employee.clear_permissions_cache
    creator_employee.reload

    expect(creator_employee.can?(:read, Category)).to be_truthy
    expect(creator_employee.can?(:create, Category)).to be_truthy
    expect(creator_employee.can?(:update, Category)).to be_falsey
  end

  # =========================================================================
  # SCENARIO 2a: Employee WITHOUT create permission gets error
  # =========================================================================
  scenario "employee without create permission cannot create new category" do
    sign_in(owner)
    visit company_permissions_path(company)

    no_permission_section = find('.role-section', text: "NoPermission")

    unless no_permission_section.has_content?("Can read Category")
      no_permission_section.click_button("Add Resource")
      within(".swal2-html-container") do
        select "Category", from: "permission[resource_name]"
        click_button "Add Resource"
      end
      expect(page).to have_content("Resource added successfully", wait: 10)
    end

    no_permission_section = find('.role-section', text: "NoPermission")
    read_label = no_permission_section.all('label').find { |l| l.text.include?("Can read Category") }
    read_checkbox = read_label.find('input[type="checkbox"]')

    unless read_checkbox.checked?
      accept_confirm do
        read_checkbox.click
      end
      expect(page).to have_selector('input[type="checkbox"]:checked', wait: 10)
    end

    company.clear_permissions_cache

    sign_in(no_permission_user)
    visit company_categories_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('[data-action*="openNewModal"]', wait: 5)

    find('[data-action*="openNewModal"]').click

    expect(page).to have_selector('form[data-action*="handleSubmit"]', wait: 10)
    fill_in 'category[name]', with: 'Should Not Be Created'
    select 'Products', from: 'category[resource_name]'

    click_button "Save Category"

    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)

    expect(Category.find_by(name: "Should Not Be Created")).to be_nil
  end

  # =========================================================================
  # SCENARIO 3: Editor with READ+UPDATE can edit category
  # =========================================================================
  scenario "employee with update permission can edit category name via show modal" do
    sign_in(owner)
    visit company_permissions_path(company)

    editor_section = find('.role-section', text: "Editor")

    unless editor_section.has_content?("Can update Category")
      editor_section.click_button("Add Resource")
      within(".swal2-html-container") do
        select "Category", from: "permission[resource_name]"
        click_button "Add Resource"
      end
      expect(page).to have_content("Resource added successfully", wait: 10)
    end

    editor_section = find('.role-section', text: "Editor")
    update_label = editor_section.all('label').find { |l| l.text.include?("Can update Category") }
    update_checkbox = update_label.find('input[type="checkbox"]')

    unless update_checkbox.checked?
      accept_confirm do
        update_checkbox.click
      end
      expect(page).to have_selector('input[type="checkbox"]:checked', wait: 10)
    end

    company.clear_permissions_cache
    editor_employee.clear_permissions_cache
    editor_employee.reload

    expect(editor_employee.can?(:update, Category)).to be_truthy

    sign_in(editor_user)
    visit company_categories_path(company)

    expect(page).to have_selector('table', wait: 10)

    target_row = find('tbody tr', text: target_category.name)
    target_row.find('[data-action*="openShowModal"]').click

    expect(page).to have_selector('.swal2-container', wait: 10)

    editable_name_field = find('[data-controller="editable"]', match: :first)
    editable_name_field.click

    expect(page).to have_selector('.editable-input', wait: 5)

    editable_name_field.find('.editable-input').fill_in(with: 'Updated Category Name')

    accept_confirm do
      editable_name_field.find('.editable-input').send_keys :enter
    end

    expect(page).to have_content("Category name updated!", wait: 10)

    target_category.reload
    expect(target_category.name).to eq('Updated Category Name')
  end

  scenario "editor can? returns correct values" do
    editor_employee.clear_permissions_cache
    editor_employee.reload

    expect(editor_employee.can?(:read, Category)).to be_truthy
    expect(editor_employee.can?(:create, Category)).to be_falsey
    expect(editor_employee.can?(:update, Category)).to be_truthy
  end

  # =========================================================================
  # SCENARIO 3a: Employee without update permission gets error
  # =========================================================================
  scenario "employee without update permission cannot edit category name" do
    sign_in(owner)
    visit company_permissions_path(company)

    editor_section = find('.role-section', text: "Editor")

    unless editor_section.has_content?("Can update Category")
      editor_section.click_button("Add Resource")
      within(".swal2-html-container") do
        select "Category", from: "permission[resource_name]"
        click_button "Add Resource"
      end
      expect(page).to have_content("Resource added successfully", wait: 10)
    end

    editor_section = find('.role-section', text: "Editor")
    update_label = editor_section.all('label').find { |l| l.text.include?("Can update Category") }
    update_checkbox = update_label.find('input[type="checkbox"]')

    unless update_checkbox.checked?
      accept_confirm do
        update_checkbox.click
      end
      expect(page).to have_selector('input[type="checkbox"]:checked', wait: 10)
    end

    update_checkbox.reload
    if update_checkbox.checked?
      accept_confirm do
        update_checkbox.click
      end
      expect(page).to have_selector('input[type="checkbox"]:not(:checked)', wait: 10)
    end

    company.clear_permissions_cache
    editor_employee.clear_permissions_cache
    editor_employee.reload

    expect(editor_employee.can?(:update, Category)).to be_falsey

    original_name = target_category.name

    sign_in(editor_user)
    visit company_categories_path(company)

    expect(page).to have_selector('table', wait: 10)

    target_row = find('tbody tr', text: target_category.name)
    target_row.find('[data-action*="openShowModal"]').click

    expect(page).to have_selector('.swal2-container', wait: 10)

    editable_name_field = find('[data-controller="editable"]', match: :first)
    editable_name_field.click

    expect(page).to have_selector('.editable-input', wait: 5)

    editable_name_field.find('.editable-input').fill_in(with: 'Attempted Update')

    accept_confirm do
      editable_name_field.find('.editable-input').send_keys :enter
    end

    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)

    target_category.reload
    expect(target_category.name).to eq(original_name)
  end

  # =========================================================================
  # SCENARIO 4: No permission employee
  # =========================================================================
  scenario "no permission employee can? returns false for all actions" do
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload

    expect(no_permission_employee.can?(:read, Category)).to be_falsey
    expect(no_permission_employee.can?(:create, Category)).to be_falsey
    expect(no_permission_employee.can?(:update, Category)).to be_falsey
  end

  # =========================================================================
  # SCENARIO 5: Owner bypass
  # =========================================================================
  scenario "owner employee can access dashboard regardless of permissions" do
    sign_in(owner)
    visit company_categories_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('button', text: 'Add')
  end

  scenario "owner can? returns true for all actions" do
    owner_employee = company.employees.find_by(user: owner)

    expect(owner_employee.owner_role?).to be_truthy
    expect(owner_employee.can?(:read, Category)).to be_truthy
    expect(owner_employee.can?(:create, Category)).to be_truthy
    expect(owner_employee.can?(:update, Category)).to be_truthy
  end

  # =========================================================================
  # SCENARIO 6: Grant permission via UI
  # =========================================================================
  scenario "owner can grant create permission to role via permissions page" do
    sign_in(owner)
    visit company_permissions_path(company)

    expect(page).to have_selector('.role-section', text: "NoPermission", wait: 20)

    no_permission_section = find('.role-section', text: "NoPermission")
    expect(no_permission_section).not_to have_content("Can create Category")

    no_permission_section.click_button("Add Resource")
    within(".swal2-html-container") do
      select "Category", from: "permission[resource_name]"
      click_button "Add Resource"
    end
    expect(page).to have_content("Resource added successfully", wait: 10)

    no_permission_section = find('.role-section', text: "NoPermission")
    create_label = no_permission_section.all('label').find { |l| l.text.include?("Can create Category") }
    create_checkbox = create_label.find('input[type="checkbox"]')

    accept_confirm do
      create_checkbox.click
    end

    expect(page).to have_selector('input[type="checkbox"]:checked', wait: 10)

    company.clear_permissions_cache
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload

    expect(no_permission_employee.can?(:create, Category)).to be_truthy
  end

  # =========================================================================
  # SCENARIO 7: Grant then use permission
  # =========================================================================
  scenario "employee granted create permission can then create new category" do
    sign_in(owner)
    visit company_permissions_path(company)

    no_permission_section = find('.role-section', text: "NoPermission")

    unless no_permission_section.has_content?("Can read Category")
      no_permission_section.click_button("Add Resource")
      within(".swal2-html-container") do
        select "Category", from: "permission[resource_name]"
        click_button "Add Resource"
      end
      expect(page).to have_content("Resource added successfully", wait: 10)
    end

    no_permission_section = find('.role-section', text: "NoPermission")
    read_label = no_permission_section.all('label').find { |l| l.text.include?("Can read Category") }
    read_checkbox = read_label.find('input[type="checkbox"]')
    unless read_checkbox.checked?
      accept_confirm do
        read_checkbox.click
      end
      expect(page).to have_selector('input[type="checkbox"]:checked', wait: 10)
    end

    no_permission_section = find('.role-section', text: "NoPermission")
    create_label = no_permission_section.all('label').find { |l| l.text.include?("Can create Category") }
    create_checkbox = create_label.find('input[type="checkbox"]')

    accept_confirm do
      create_checkbox.click
    end
    expect(page).to have_selector('input[type="checkbox"]:checked', wait: 10)

    company.clear_permissions_cache
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload
    expect(no_permission_employee.can?(:create, Category)).to be_truthy

    company.clear_permissions_cache
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload

    sign_in(no_permission_user)
    visit company_categories_path(company)

    find('[data-action*="openNewModal"]').click
    expect(page).to have_selector('form[data-action*="handleSubmit"]', wait: 10)
    fill_in 'category[name]', with: 'Created After Grant'
    select 'Products', from: 'category[resource_name]'

    click_button "Save Category"

    expect(page).to have_content("created successfully!", wait: 10)
    expect(page).to have_selector('tbody tr', wait: 10)

    expect(Category.find_by(name: "Created After Grant")).to be_present
  end

  # =========================================================================
  # SCENARIO 8: Remove permission then verify cannot use
  # =========================================================================
  scenario "employee with create permission removed cannot create new category" do
    sign_in(owner)
    visit company_permissions_path(company)

    creator_section = find('.role-section', text: "Creator")
    create_label = creator_section.all('label').find { |l| l.text.include?("Can create Category") }
    create_checkbox = create_label.find('input[type="checkbox"]')

    unless create_checkbox.checked?
      accept_confirm do
        create_checkbox.click
      end
      expect(page).to have_selector('input[type="checkbox"]:checked', wait: 10)
    end

    company.clear_permissions_cache
    creator_employee.clear_permissions_cache
    creator_employee.reload
    expect(creator_employee.can?(:create, Category)).to be_truthy

    create_checkbox.reload
    accept_confirm do
      create_checkbox.click
    end
    expect(page).to have_selector('input[type="checkbox"]:not(:checked)', wait: 10)

    company.clear_permissions_cache
    creator_employee.clear_permissions_cache
    creator_employee.reload
    expect(creator_employee.can?(:create, Category)).to be_falsey

    sign_in(creator_user)
    visit company_categories_path(company)

    find('[data-action*="openNewModal"]').click
    expect(page).to have_selector('form[data-action*="handleSubmit"]', wait: 10)
    fill_in 'category[name]', with: 'Should Be Rejected'
    select 'Products', from: 'category[resource_name]'

    click_button "Save Category"

    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)
    expect(Category.find_by(name: "Should Be Rejected")).to be_nil
  end

  # =========================================================================
  # SCENARIO 9: Remove read permission redirects user
  # =========================================================================
  scenario "reader is redirected after read permission removed" do
    sign_in(owner)
    visit company_permissions_path(company)

    reader_section = find('.role-section', text: "Reader")
    read_label = reader_section.all('label').find { |l| l.text.include?("Can read Category") }
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
    visit company_categories_path(company)

    expect(page).not_to have_selector('table')
    expect(page).to have_content("You are not authorized to perform this action.")
  end

  # =========================================================================
  # SCENARIO 10: Permission toggle off then on
  # =========================================================================
  scenario "permission toggle off then on works correctly" do
    sign_in(owner)
    visit company_permissions_path(company)

    creator_section = find('.role-section', text: "Creator")
    %w[read create].each do |action|
      label = creator_section.all('label').find { |l| l.text.include?("Can #{action} Category") }
      checkbox = label&.find('input[type="checkbox"]')
      next unless checkbox && !checkbox.checked?
      accept_confirm do
        checkbox.click
      end
      expect(page).to have_selector('input[type="checkbox"]:checked', wait: 10)
    end

    company.clear_permissions_cache
    creator_employee.clear_permissions_cache
    creator_employee.reload
    expect(creator_employee.can?(:create, Category)).to be_truthy

    # Toggle OFF
    creator_section = find('.role-section', text: "Creator")
    create_label = creator_section.all('label').find { |l| l.text.include?("Can create Category") }
    create_checkbox = create_label.find('input[type="checkbox"]')

    accept_confirm do
      create_checkbox.click
    end
    expect(page).to have_selector('input[type="checkbox"]:not(:checked)', wait: 10)

    company.clear_permissions_cache
    creator_employee.clear_permissions_cache
    creator_employee.reload
    expect(creator_employee.can?(:create, Category)).to be_falsey

    # Toggle ON again
    create_checkbox.reload
    accept_confirm do
      create_checkbox.click
    end
    expect(page).to have_selector('input[type="checkbox"]:checked', wait: 10)

    company.clear_permissions_cache
    creator_employee.clear_permissions_cache
    creator_employee.reload
    expect(creator_employee.can?(:create, Category)).to be_truthy
  end

  # =========================================================================
  # SCENARIO 11: Grant read permission and access dashboard
  # =========================================================================
  scenario "owner can grant read permission to role via permissions page" do
    sign_in(owner)
    visit company_permissions_path(company)

    no_permission_section = find('.role-section', text: "NoPermission")

    no_permission_section.click_button("Add Resource")
    within(".swal2-html-container") do
      select "Category", from: "permission[resource_name]"
      click_button "Add Resource"
    end
    expect(page).to have_content("Resource added successfully", wait: 10)

    no_permission_section = find('.role-section', text: "NoPermission")
    read_label = no_permission_section.all('label').find { |l| l.text.include?("Can read Category") }
    read_checkbox = read_label.find('input[type="checkbox"]')

    accept_confirm do
      read_checkbox.click
    end

    expect(page).to have_selector('input[type="checkbox"]:checked', wait: 10)

    company.clear_permissions_cache
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload

    expect(no_permission_employee.can?(:read, Category)).to be_truthy
  end

  scenario "owner can grant update permission to role via permissions page" do
    sign_in(owner)
    visit company_permissions_path(company)

    no_permission_section = find('.role-section', text: "NoPermission")

    no_permission_section.click_button("Add Resource")
    within(".swal2-html-container") do
      select "Category", from: "permission[resource_name]"
      click_button "Add Resource"
    end
    expect(page).to have_content("Resource added successfully", wait: 10)

    no_permission_section = find('.role-section', text: "NoPermission")
    update_label = no_permission_section.all('label').find { |l| l.text.include?("Can update Category") }
    update_checkbox = update_label.find('input[type="checkbox"]')

    accept_confirm do
      update_checkbox.click
    end

    expect(page).to have_selector('input[type="checkbox"]:checked', wait: 10)

    company.clear_permissions_cache
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload

    expect(no_permission_employee.can?(:update, Category)).to be_truthy
  end

  # =========================================================================
  # SCENARIO 12: Remove update permission
  # =========================================================================
  scenario "owner can remove update permission from role via permissions page" do
    # First grant update permission using editor role
    sign_in(owner)
    visit company_permissions_path(company)

    editor_section = find('.role-section', text: "Editor")
    expect(editor_section).to have_content("Can update Category")

    update_label = editor_section.all('label').find { |l| l.text.include?("Can update Category") }
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

    expect(editor_employee.can?(:update, Category)).to be_falsey
  end
end
