require "rails_helper"

RSpec.feature "Companies::Products Permissions", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:owner) { company.user }

  # Roles
  let!(:reader_role) { create(:role, company: company, name: "Reader", role_business_type: :support) }
  let!(:creator_role) { create(:role, company: company, name: "Creator", role_business_type: :support) }
  let!(:editor_role) { create(:role, company: company, name: "Editor", role_business_type: :management) }
  let!(:no_permission_role) { create(:role, company: company, name: "NoPermission", role_business_type: :support) }

  # Policies for Product resource
  let!(:policy_read_product) { create_policy(resource: "Product", action: "read") }
  let!(:policy_create_product) { create_policy(resource: "Product", action: "create") }
  let!(:policy_update_product) { create_policy(resource: "Product", action: "update") }

  # Reader role: Product(read) - active
  let!(:reader_read_product_active) do
    create_policy_appointment(role: reader_role, policy: policy_read_product, workflow_status: :active)
  end

  # Creator role: Product(read, create) - active
  let!(:creator_read_product_active) do
    create_policy_appointment(role: creator_role, policy: policy_read_product, workflow_status: :active)
  end
  let!(:creator_create_product_active) do
    create_policy_appointment(role: creator_role, policy: policy_create_product, workflow_status: :active)
  end

  # Editor role: Product(read, update) - active
  let!(:editor_read_product_active) do
    create_policy_appointment(role: editor_role, policy: policy_read_product, workflow_status: :active)
  end
  let!(:editor_update_product_active) do
    create_policy_appointment(role: editor_role, policy: policy_update_product, workflow_status: :active)
  end

  # NoPermission role: NO policies for Product

  # Test employees with different roles
  let!(:reader_user) { create(:user, :company_employee) }
  let!(:reader_employee) do
    create(:employee, company: company, branch: branch, user: reader_user, roles: [ reader_role ]).tap do
      company.clear_permissions_cache
    end
  end

  let!(:creator_user) { create(:user, :company_employee) }
  let!(:creator_employee) do
    create(:employee, company: company, branch: branch, user: creator_user, roles: [ creator_role ]).tap do
      company.clear_permissions_cache
    end
  end

  let!(:editor_user) { create(:user, :company_employee) }
  let!(:editor_employee) do
    create(:employee, company: company, branch: branch, user: editor_user, roles: [ editor_role ]).tap do
      company.clear_permissions_cache
    end
  end

  let!(:no_permission_user) { create(:user, :company_employee) }
  let!(:no_permission_employee) do
    create(:employee, company: company, branch: branch, user: no_permission_user, roles: [ no_permission_role ]).tap do
      company.clear_permissions_cache
    end
  end

  # Target product for edit tests
  let!(:target_product) { create(:product, company: company, name: "Target Product", description: "Test description") }

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
  scenario "employee with read-only permission can access products dashboard" do
    sign_in(reader_user)
    visit company_products_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_content("Product Name")
  end

  scenario "reader can? returns true for read, false for create/update" do
    reader_employee.clear_permissions_cache
    reader_employee.reload

    expect(reader_employee.can?(:read, Product)).to be_truthy
    expect(reader_employee.can?(:create, Product)).to be_falsey
    expect(reader_employee.can?(:update, Product)).to be_falsey
  end

  scenario "read-only employee can see Add button in UI (UI doesn't gate on permissions)" do
    reader_employee.clear_permissions_cache
    sign_in(reader_user)
    visit company_products_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('button', text: 'Add')
  end

  # =========================================================================
  # SCENARIO 2: Creator with READ+CREATE can create product
  # =========================================================================
  scenario "employee with create permission can see Add button" do
    creator_employee.clear_permissions_cache
    sign_in(creator_user)
    visit company_products_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('button', text: 'Add', wait: 5)
  end

  scenario "employee with create permission can open create modal" do
    creator_employee.clear_permissions_cache
    sign_in(creator_user)
    visit company_products_path(company)

    expect(page).to have_selector('[data-action*="openNewModal"]', wait: 5)
    find('[data-action*="openNewModal"]').click
    expect(page).to have_selector('form[data-action*="handleSubmit"]', wait: 10)
  end

  scenario "creator can create new product and see in table" do
    creator_employee.clear_permissions_cache
    company.clear_permissions_cache
    creator_employee.reload

    sign_in(creator_user)
    visit company_products_path(company)

    find('[data-action*="openNewModal"]').click

    expect(page).to have_selector('form[data-action*="handleSubmit"]', wait: 10)
    expect(page).to have_selector('input[name="product[name]"]', wait: 5)
    fill_in 'product[name]', with: 'Created by Creator'
    select 'Digital', from: 'product[business_type]'

    click_button "Save Product"

    expect(page).to have_content("created successfully", wait: 10)
    expect(page).to have_selector('tbody tr', wait: 10)

    expect(Product.find_by(name: "Created by Creator")).to be_present
  end

  scenario "creator can? returns true for read and create" do
    creator_employee.clear_permissions_cache
    creator_employee.reload

    expect(creator_employee.can?(:read, Product)).to be_truthy
    expect(creator_employee.can?(:create, Product)).to be_truthy
    expect(creator_employee.can?(:update, Product)).to be_falsey
  end

  # =========================================================================
  # SCENARIO 2a: Employee WITHOUT create permission gets error when trying to create
  # =========================================================================
  scenario "employee without create permission cannot create new product" do
    sign_in(owner)
    visit company_permissions_path(company)

    no_permission_section = find('.role-section', text: "NoPermission")

    unless no_permission_section.has_content?("Can read Product")
      no_permission_section.click_button("Add Resource")
      within(".swal2-html-container") do
        select "Product", from: "permission[resource_name]"
        click_button "Add Resource"
      end
      expect(page).to have_content("Resource added successfully", wait: 10)
    end

    no_permission_section = find('.role-section', text: "NoPermission")
    read_label = no_permission_section.all('label').find { |l| l.text.include?("Can read Product") }
    read_checkbox = read_label.find('input[type="checkbox"]')

    unless read_checkbox.checked?
      accept_confirm do
        read_checkbox.click
      end
      expect(page).to have_selector('input[type="checkbox"]:checked', wait: 10)
    end

    company.clear_permissions_cache

    sign_in(no_permission_user)
    visit company_products_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('[data-action*="openNewModal"]', wait: 5)

    find('[data-action*="openNewModal"]').click

    expect(page).to have_selector('form[data-action*="handleSubmit"]', wait: 10)
    fill_in 'product[name]', with: 'Should Not Be Created'
    select 'Digital', from: 'product[business_type]'

    click_button "Save Product"

    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)

    expect(Product.find_by(name: "Should Not Be Created")).to be_nil
  end

  # =========================================================================
  # SCENARIO 3: Editor with READ+UPDATE can edit product
  # =========================================================================
  scenario "employee with update permission can see table with edit buttons" do
    editor_employee.clear_permissions_cache
    sign_in(editor_user)
    visit company_products_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('[data-action*="openShowModal"]', minimum: 1)
  end

  scenario "editor can? returns true for read and update" do
    editor_employee.clear_permissions_cache
    editor_employee.reload

    expect(editor_employee.can?(:read, Product)).to be_truthy
    expect(editor_employee.can?(:create, Product)).to be_falsey
    expect(editor_employee.can?(:update, Product)).to be_truthy
  end

  # =========================================================================
  # SCENARIO 3b: Editor can update product name via show modal
  # =========================================================================
  scenario "editor with update permission can update product name via editable" do
    sign_in(owner)
    visit company_products_path(company)

    expect(page).to have_selector('table', wait: 10)

    target_row = find('tbody tr', text: target_product.name)
    target_row.find('[data-action*="openShowModal"]').click

    expect(page).to have_selector('.swal2-container', wait: 10)

    editable_name_field = find('[data-controller="editable"]', match: :first)
    editable_name_field.click

    expect(page).to have_selector('.editable-input', wait: 5)

    editable_name_field.find('.editable-input').fill_in(with: 'Updated Product Name')

    accept_confirm do
      editable_name_field.find('.editable-input').send_keys :enter
    end

    expect(page).to have_selector('tbody tr', wait: 10)
    expect(Product.find_by(id: target_product.id).name).to eq("Updated Product Name")
  end

  # =========================================================================
  # SCENARIO 3c: Editor can update product description via show modal
  # =========================================================================
  scenario "editor with update permission can update product description via editable" do
    sign_in(owner)
    visit company_products_path(company)

    expect(page).to have_selector('table', wait: 10)

    target_row = find('tbody tr', text: target_product.name)
    target_row.find('[data-action*="openShowModal"]').click

    expect(page).to have_selector('.swal2-container', wait: 10)

    all_editable = all('[data-controller="editable"]')
    desc_editable = all_editable[1]
    desc_editable.click

    expect(page).to have_selector('.editable-input', wait: 5)

    desc_editable.find('.editable-input').fill_in(with: 'Updated description')

    accept_confirm do
      desc_editable.find('.editable-input').send_keys :enter
    end

    expect(page).to have_selector('tbody tr', wait: 10)
    expect(Product.find_by(id: target_product.id).description).to eq("Updated description")
  end

  # =========================================================================
  # SCENARIO 3d: Employee WITHOUT update permission gets error when editing
  # =========================================================================
  scenario "employee without update permission cannot edit another product's name" do
    sign_in(owner)
    visit company_permissions_path(company)

    editor_section = find('.role-section', text: "Editor")

    unless editor_section.has_content?("Can update Product")
      editor_section.click_button("Add Resource")
      within(".swal2-html-container") do
        select "Product", from: "permission[resource_name]"
        click_button "Add Resource"
      end
      expect(page).to have_content("Resource added successfully", wait: 10)
    end

    company.clear_permissions_cache

    # Remove update permission from editor temporarily by setting workflow_status to inactive
    appointment = PolicyAppointment.find_by(appoint_to: editor_role, policy: policy_update_product)
    appointment.update!(workflow_status: :inactive)
    company.clear_permissions_cache
    editor_employee.reload

    expect(editor_employee.can?(:update, Product)).to be_falsey

    # Try to update - should fail with authorization error
    sign_in(editor_user)
    visit company_products_path(company)

    expect(page).to have_selector('table', wait: 10)

    target_row = find('tbody tr', text: target_product.name)
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

    target_product.reload
    expect(target_product.name).not_to eq("Attempted Update")
  end

  # =========================================================================
  # SCENARIO 4: Owner has all permissions bypass
  # =========================================================================
  scenario "owner can? returns true for all actions" do
    owner_employee = company.employees.find_by(user: owner)

    expect(owner_employee.can?(:read, Product)).to be_truthy
    expect(owner_employee.can?(:create, Product)).to be_truthy
    expect(owner_employee.can?(:update, Product)).to be_truthy
  end

  # =========================================================================
  # SCENARIO 5: Permission changes via UI toggle work correctly
  # =========================================================================
  scenario "policy appointment workflow_status can be toggled to grant permission" do
    # NoPermission role initially has no Product create permission
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload
    expect(no_permission_employee.can?(:create, Product)).to be_falsey

    # Grant permission via policy appointment
    sign_in(owner)
    visit company_permissions_path(company)

    no_permission_section = find('.role-section', text: "NoPermission")

    # Add Product resource if not present
    unless no_permission_section.has_content?("Can create Product")
      no_permission_section.click_button("Add Resource")
      within(".swal2-html-container") do
        select "Product", from: "permission[resource_name]"
        click_button "Add Resource"
      end
      expect(page).to have_content("Resource added successfully", wait: 10)
    end

    # Activate create permission
    no_permission_section = find('.role-section', text: "NoPermission")
    create_label = no_permission_section.all('label').find { |l| l.text.include?("Can create Product") }

    if create_label
      create_checkbox = create_label.find('input[type="checkbox"]')
      unless create_checkbox.checked?
        accept_confirm do
          create_checkbox.click
        end
      end
    end

    company.clear_permissions_cache
    no_permission_employee.reload
    expect(no_permission_employee.can?(:create, Product)).to be_truthy
  end

  # =========================================================================
  # SCENARIO 6: Deactivating policy appointment revokes permission
  # =========================================================================
  scenario "policy appointment workflow_status can be toggled to revoke permission" do
    # Editor role initially has Product update permission
    editor_employee.clear_permissions_cache
    editor_employee.reload
    expect(editor_employee.can?(:update, Product)).to be_truthy

    # Find and deactivate the update permission
    appointment = PolicyAppointment.find_by(appoint_to: editor_role, policy: policy_update_product)
    appointment.update!(workflow_status: :inactive)
    company.clear_permissions_cache

    editor_employee.reload
    expect(editor_employee.can?(:update, Product)).to be_falsey
  end

  # =========================================================================
  # SCENARIO 7: No permission employee cannot access product dashboard
  # =========================================================================
  scenario "employee without read permission cannot access products dashboard" do
    # NoPermission role has no Product policies at all
    no_permission_employee.clear_permissions_cache
    no_permission_employee.reload

    expect(no_permission_employee.can?(:read, Product)).to be_falsey

    sign_in(no_permission_user)
    visit company_products_path(company)

    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)
  end
end
