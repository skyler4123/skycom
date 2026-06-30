require "rails_helper"

RSpec.feature "Companies::Permissions Management", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:owner) { company.user }

  # Use let! to ensure roles are created before visiting the page
  let!(:admin_role) { create(:role, company: company, name: "admin", business_type: :administrative) }
  let!(:manager_role) { create(:role, company: company, name: "manager", business_type: :management) }
  let!(:cashier_role) { create(:role, company: company, name: "cashier", business_type: :support) }

  # Use let! for policies
  let!(:policy_read_product) { create_policy(resource: "Product", action: "read") }
  let!(:policy_create_product) { create_policy(resource: "Product", action: "create") }
  let!(:policy_update_product) { create_policy(resource: "Product", action: "update") }
  let!(:policy_delete_product) { create_policy(resource: "Product", action: "delete") }
  let!(:policy_read_order) { create_policy(resource: "Order", action: "read") }
  let!(:policy_create_order) { create_policy(resource: "Order", action: "create") }
  let!(:policy_read_customer) { create_policy(resource: "Customer", action: "read") }
  let!(:policy_create_customer) { create_policy(resource: "Customer", action: "create") }

  # Admin role: Product(read) - ONE active for can? test; Order both active
  let!(:admin_read_product_active) do
    create_policy_appointment(role: admin_role, policy: policy_read_product, workflow_status: :active)
  end
  let!(:admin_create_product_inactive) do
    create_policy_appointment(role: admin_role, policy: policy_create_product, workflow_status: :inactive)
  end
  let!(:admin_read_order_inactive) do
    create_policy_appointment(role: admin_role, policy: policy_read_order, workflow_status: :inactive)
  end
  let!(:admin_create_order_inactive) do
    create_policy_appointment(role: admin_role, policy: policy_create_order, workflow_status: :inactive)
  end

  # Manager role: Product(read, create, update, delete), Order(read)
  let!(:manager_read_product_active) do
    create_policy_appointment(role: manager_role, policy: policy_read_product, workflow_status: :active)
  end
  let!(:manager_create_product_active) do
    create_policy_appointment(role: manager_role, policy: policy_create_product, workflow_status: :active)
  end
  let!(:manager_update_product_active) do
    create_policy_appointment(role: manager_role, policy: policy_update_product, workflow_status: :active)
  end
  let!(:manager_delete_product_active) do
    create_policy_appointment(role: manager_role, policy: policy_delete_product, workflow_status: :active)
  end
  let!(:manager_read_order_active) do
    create_policy_appointment(role: manager_role, policy: policy_read_order, workflow_status: :active)
  end

  # Cashier role: Order(read) only
  let!(:cashier_read_order_active) do
    create_policy_appointment(role: cashier_role, policy: policy_read_order, workflow_status: :active)
  end

  # Use let! for employees
  let!(:admin_user) { create(:user, :company_employee) }
  let!(:admin_employee) do
    emp = create(:employee, company: company, branch: branch, user: admin_user)
    create(:role_appointment, company: company, appoint_to: emp, role: admin_role)
    emp
  end

  let!(:unauthorized_user) { create(:user, :company_employee) }
  let!(:unauthorized_employee) do
    emp = create(:employee, company: company, branch: branch, user: unauthorized_user)
    create(:role_appointment, company: company, appoint_to: emp, role: manager_role)
    emp
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

  def create_policy_appointment(role:, policy:, workflow_status:, business_type: nil)
    appointment = PolicyAppointment.find_or_create_by!(
      company: company,
      policy: policy,
      appoint_to: role
    )
    appointment.update!(workflow_status: workflow_status)
    appointment.update!(business_type: business_type) if business_type
    appointment
  end

  before do
    company.clear_permissions_cache
  end

  scenario "can access Permissions Page after signed in" do
    sign_in(owner)
    visit company_permissions_path(company)

    expect(page).to have_selector('.role-section', wait: 20)
    expect(page).to have_content("Permissions")
    expect(page).to have_content("Manage role-based permissions by toggling policies")
  end

  scenario "page loads and displays non-owner roles only" do
    sign_in(owner)
    visit company_permissions_path(company)

    expect(page).to have_selector('.role-section', count: 3, wait: 20)
    expect(page).not_to have_content("owner")

    expect(page).to have_content("admin")
    expect(page).to have_content("manager")
    expect(page).to have_content("cashier")
  end

  scenario "click badge to activate permission via modal" do
    sign_in(owner)
    visit company_permissions_path(company)

    expect(page).to have_selector('.role-section', text: "admin", wait: 20)

    admin_section = find('.role-section', text: "admin")
    resource_section = admin_section.find('.resource-section', text: 'Product')
    inactive_badge = resource_section.all('button').find { |b| b.text.match?(/create/i) }
    expect(inactive_badge).to have_text(/create/i)
    inactive_badge.click

    expect(page).to have_selector('.swal2-html-container')
    expect(page).to have_content("Configure permission and tag conditions")

    within(".swal2-html-container") do
      toggle = find('[data-status-toggle]')
      expect(toggle).to have_text(/inactive/i)
      toggle.click
      expect(toggle).to have_text(/active/i)

      click_button "Save"
    end

    expect(page).to have_content("create permission updated", wait: 10)
    admin_section = find('.role-section', text: "admin")
    expect(admin_section).to have_selector('button:not([data-controller]) .bg-blue-600, button.bg-blue-600', text: /create/, wait: 10)
  end

  scenario "click badge to deactivate permission via modal" do
    sign_in(owner)
    visit company_permissions_path(company)

    expect(page).to have_selector('.role-section', text: "admin", wait: 20)

    admin_section = find('.role-section', text: "admin")
    resource_section = admin_section.find('.resource-section', text: 'Product')
    active_badge = resource_section.all('button').find { |b| b.text.match?(/read/i) }
    expect(active_badge).to have_text(/read/i)
    active_badge.click

    expect(page).to have_selector('.swal2-html-container')

    within(".swal2-html-container") do
      toggle = find('[data-status-toggle]')
      expect(toggle).to have_text(/active/i)
      toggle.click
      expect(toggle).to have_text(/inactive/i)

      click_button "Save"
    end

    expect(page).to have_content("read permission updated", wait: 10)
  end

  scenario "active to inactive changes can? to return false", :js do
    company.clear_permissions_cache
    admin_employee.clear_permissions_cache
    admin_employee.reload

    expect(admin_employee.can?(:read, policy_read_product.resource.constantize)).to be_truthy

    sign_in(owner)
    visit company_permissions_path(company)

    expect(page).to have_selector('.role-section', text: "admin", wait: 20)

    admin_section = find('.role-section', text: "admin")
    resource_section = admin_section.find('.resource-section', text: 'Product')
    active_badge = resource_section.all('button').find { |b| b.text.match?(/read/i) }
    active_badge.click

    expect(page).to have_selector('.swal2-html-container')

    within(".swal2-html-container") do
      find('[data-status-toggle]').click
      click_button "Save"
    end

    expect(page).to have_content("read permission updated", wait: 10)

    company.clear_permissions_cache
    admin_employee.clear_permissions_cache
    admin_employee.reload

    expect(admin_employee.can?(:read, policy_read_product.resource.constantize)).to be_falsey
  end

  scenario "inactive to active changes can? to return true", :js do
    sign_in(owner)
    visit company_permissions_path(company)

    expect(page).to have_selector('.role-section', text: "admin", wait: 20)

    admin_section = find('.role-section', text: "admin")
    resource_section = admin_section.find('.resource-section', text: 'Product')
    inactive_badge = resource_section.all('button').find { |b| b.text.match?(/create/i) }
    inactive_badge.click

    expect(page).to have_selector('.swal2-html-container')

    within(".swal2-html-container") do
      find('[data-status-toggle]').click
      click_button "Save"
    end

    expect(page).to have_content("create permission updated", wait: 10)

    company.clear_permissions_cache
    admin_employee.clear_permissions_cache
    admin_employee.reload

    target_class = policy_create_product.resource.constantize
    expect(admin_employee.can?(:create, target_class)).to be_truthy
  end

  scenario "unauthorized user sees no access message" do
    sign_in(unauthorized_user)
    visit company_permissions_path(company)

    expect(page).not_to have_selector('.role-section')
    expect(page).to have_content("You are not authorized to perform this action.")
  end

  scenario "unsigned in user can not access to this page" do
    visit company_permissions_path(company)

    expect(page).to have_current_path("/")
  end

  scenario "each role displays only resources with policies assigned to it" do
    sign_in(owner)
    visit company_permissions_path(company)

    expect(page).to have_selector('.role-section', count: 3, wait: 20)

    admin_section = find('.role-section', text: "admin")
    expect(admin_section).to have_content("Product")
    expect(admin_section).not_to have_content("Customer")

    manager_section = find('.role-section', text: "manager")
    expect(manager_section).to have_content("Product")
    expect(manager_section).to have_content("Order")
    expect(manager_section).not_to have_content("Customer")

    cashier_section = find('.role-section', text: "cashier")
    expect(cashier_section).to have_content("Order")
    expect(cashier_section).not_to have_content("Product")
    expect(cashier_section).not_to have_content("Customer")
  end

  scenario "owner role with all all policy is hidden from permissions page" do
    company.reload

    owner_role = company.roles.find_by(name: "owner")
    expect(owner_role).to be_present
    expect(owner_role.business_type).to eq("owner")

    owner_policy = company.policies.find_by(resource: "all", action: "all")
    expect(owner_policy).to be_present
    expect(owner_policy.business_type).to eq("owner")

    permissions_data = company.permissions

    expect(permissions_data.map { |r| r[:name] }).not_to include("owner")
    expect(permissions_data.flat_map { |r| r[:policies].map { |p| p[:resource] } }).not_to include("all")

    sign_in(owner)
    visit company_permissions_path(company)

    expect(page).not_to have_content("owner")
    expect(page).not_to have_content("Can all all")
  end

  scenario "owner employee can? returns true for any action and resource" do
    company.reload
    owner_employee = company.employees.find_by(user: owner)

    expect(owner_employee).to be_present
    expect(owner_employee.business_type).to eq("owner")
    expect(owner_employee.role_appointments.first.business_type).to eq("owner")

    expect(owner_employee.can?(:create, Product)).to be_truthy
    expect(owner_employee.can?(:read, Product)).to be_truthy
    expect(owner_employee.can?(:update, Product)).to be_truthy
    expect(owner_employee.can?(:delete, Product)).to be_truthy

    expect(owner_employee.can?(:create, Order)).to be_truthy
    expect(owner_employee.can?(:anything, :any_resource)).to be_truthy
  end

  scenario "click Add Resource button opens modal" do
    sign_in(owner)
    visit company_permissions_path(company)

    expect(page).to have_selector('.role-section', text: "manager", wait: 20)

    find('.role-section', text: "manager").click_button("Add Resource")

    expect(page).to have_selector('.swal2-html-container')
    expect(page).to have_content("Add Resource to manager")
  end

  scenario "modal shows only unassigned resources" do
    sign_in(owner)
    visit company_permissions_path(company)

    manager_section = find('.role-section', text: "manager")
    expect(manager_section).to have_content("Product")
    expect(manager_section).to have_content("Order")

    manager_section.click_button("Add Resource")

    within(".swal2-html-container") do
      expect(page).to have_content("Customer")
      expect(page).to have_content("Select a resource")
    end
  end

scenario "submit shows success toast and closes modal" do
    sign_in(owner)
    visit company_permissions_path(company)

    find('.role-section', text: "cashier").click_button("Add Resource")
    expect(page).to have_selector('.swal2-html-container')

    within(".swal2-html-container") do
      select "Product", from: "permission[resource_name]"
      click_button "Add Resource"
    end

    expect(page).to have_content("Resource added successfully", wait: 10)
    expect(page).not_to have_selector('.swal2-html-container')
  end

  scenario "page refreshes after successful add" do
    sign_in(owner)
    visit company_permissions_path(company)

    cashier_section = find('.role-section', text: "cashier")
    expect(cashier_section).not_to have_content("Product")

    cashier_section.click_button("Add Resource")

    within(".swal2-html-container") do
      select "Product", from: "permission[resource_name]"
      click_button "Add Resource"
    end

    expect(page).to have_content("Resource added successfully", wait: 10)

    cashier_section = find('.role-section', text: "cashier")
    expect(cashier_section).to have_content("Product")
  end

  scenario "click Cancel button closes modal" do
    sign_in(owner)
    visit company_permissions_path(company)

    find('.role-section', text: "manager").click_button("Add Resource")
    expect(page).to have_selector('.swal2-html-container')

    within(".swal2-html-container") do
      click_button "Cancel"
    end

    expect(page).not_to have_selector('.swal2-html-container')
  end

  scenario "duplicate resource shows error toast" do
    sign_in(owner)
    visit company_permissions_path(company)

    cashier_section = find('.role-section', text: "cashier")
    expect(cashier_section).to have_content("Order")
    expect(cashier_section).not_to have_content("Customer")

    cashier_section.click_button("Add Resource")
    expect(page).to have_content("Select a resource")
    expect(page).to have_content("Customer")

    within(".swal2-html-container") do
      select "Customer", from: "permission[resource_name]"
      click_button "Add Resource"
    end

    expect(page).to have_content("Resource added successfully", wait: 10)

    cashier_section = find('.role-section', text: "cashier")
    expect(cashier_section).to have_content("Customer")

    cashier_section.click_button("Add Resource")
    expect(page).to have_selector('.swal2-html-container')
    expect(page).to have_content("Select a resource")
    expect(page).not_to have_content('option[value="Customer"]')
  end

  scenario "unassigned resources list updates after adding resource" do
    sign_in(owner)
    visit company_permissions_path(company)

    manager_section = find('.role-section', text: "manager")
    expect(manager_section).to have_content("Product")
    expect(manager_section).to have_content("Order")
    expect(manager_section).not_to have_content("Customer")

    manager_section.click_button("Add Resource")

    within(".swal2-html-container") do
      expect(page).to have_content("Customer")
      expect(page).not_to have_content('option[value="Product"]')
      expect(page).not_to have_content('option[value="Order"]')
    end

    within(".swal2-html-container") do
      select "Customer", from: "permission[resource_name]"
      click_button "Add Resource"
    end

    expect(page).to have_content("Resource added successfully", wait: 10)

    manager_section = find('.role-section', text: "manager")
    expect(manager_section).to have_content("Customer")
  end

  scenario "add and save tag conditions via modal" do
    sign_in(owner)
    visit company_permissions_path(company)

    expect(page).to have_selector('.role-section', text: "admin", wait: 20)

    admin_section = find('.role-section', text: "admin")
    resource_section = admin_section.find('.resource-section', text: 'Product')
    inactive_badge = resource_section.all('button').find { |b| b.text.match?(/create/i) }
    inactive_badge.click

    expect(page).to have_selector('.swal2-html-container')

    within(".swal2-html-container") do
      find('[data-status-toggle]').click

      find('[data-tag-key]').set("usage_status")
      find('[data-tag-value]').set("secondhand")

      click_button "Add Condition"
      expect(page).to have_selector('[data-tag-row]', count: 2)

      all('[data-tag-row]').last.find('[data-tag-key]').set("brand")
      all('[data-tag-row]').last.find('[data-tag-value]').set("Apple")

      click_button "Save"
    end

    expect(page).to have_content("create permission updated", wait: 10)

    admin_section = find('.role-section', text: "admin")
    resource_section = admin_section.find('.resource-section', text: 'Product')
    badge = resource_section.all('button').find { |b| b.text.match?(/create/i) }
    badge.click

    expect(page).to have_selector('.swal2-html-container')

    within(".swal2-html-container") do
      expect(page).to have_selector('[data-tag-row]', count: 2)
      expect(page).to have_field("Key", with: "usage_status")
      expect(page).to have_field("Value", with: "secondhand")
      expect(page).to have_field("Key", with: "brand")
      expect(page).to have_field("Value", with: "Apple")
    end
  end

  scenario "clear all tag conditions via modal" do
    sign_in(owner)
    visit company_permissions_path(company)

    expect(page).to have_selector('.role-section', text: "admin", wait: 20)

    find('.role-section', text: "admin").find('.resource-section', text: 'Product')
      .find('button', text: /create/i).click

    within(".swal2-html-container") do
      find('[data-tag-key]').set("usage_status")
      find('[data-tag-value]').set("secondhand")
      click_button "Save"
    end

    expect(page).to have_content("create permission updated", wait: 10)

    find('.role-section', text: "admin").find('.resource-section', text: 'Product')
      .find('button', text: /create/i).click

    within(".swal2-html-container") do
      all('[data-tag-row]').each do |row|
        row.find('button[data-action*="removeTagRow"]').click
      end
      click_button "Save"
    end

    expect(page).to have_content("create permission updated", wait: 10)

    find('.role-section', text: "admin").find('.resource-section', text: 'Product')
      .find('button', text: /create/i).click

    within(".swal2-html-container") do
      rows = all('[data-tag-row]')
      expect(rows.length).to eq(1)
      expect(rows.first.find('[data-tag-key]').value).to be_blank
      expect(rows.first.find('[data-tag-value]').value).to be_blank
    end
  end

  scenario "toggle permission preserves tag conditions" do
    sign_in(owner)
    visit company_permissions_path(company)

    expect(page).to have_selector('.role-section', text: "admin", wait: 20)

    find('.role-section', text: "admin").find('.resource-section', text: 'Product')
      .all('button').find { |b| b.text.match?(/create/i) }.click

    within(".swal2-html-container") do
      find('[data-status-toggle]').click
      find('[data-tag-key]').set("usage_status")
      find('[data-tag-value]').set("secondhand")
      click_button "Save"
    end

    expect(page).to have_content("create permission updated", wait: 10)

    find('.role-section', text: "admin").find('.resource-section', text: 'Product')
      .find('button', text: /create/i).click

    within(".swal2-html-container") do
      find('[data-status-toggle]').click
      click_button "Save"
    end

    expect(page).to have_content("create permission updated", wait: 10)

    find('.role-section', text: "admin").find('.resource-section', text: 'Product')
      .find('button', text: /create/i).click

    within(".swal2-html-container") do
      find('[data-status-toggle]').click
      click_button "Save"
    end

    expect(page).to have_content("create permission updated", wait: 10)

    find('.role-section', text: "admin").find('.resource-section', text: 'Product')
      .find('button', text: /create/i).click

    within(".swal2-html-container") do
      expect(page).to have_selector('[data-tag-row]', count: 1)
      expect(page).to have_field("Key", with: "usage_status")
      expect(page).to have_field("Value", with: "secondhand")
    end
  end

  scenario "tag conditions affect can? for instance-level check", :js do
    tagged_product = create(:product, company: company, branch: branch, name: "Tagged Product")
    tagged_product.attach_tag(key: "usage_status", value: "secondhand")

    untagged_product = create(:product, company: company, branch: branch, name: "Untagged Product")

    sign_in(owner)
    visit company_permissions_path(company)

    expect(page).to have_selector('.role-section', text: "admin", wait: 20)

    admin_section = find('.role-section', text: "admin")
    resource_section = admin_section.find('.resource-section', text: 'Product')
    resource_section.all('button').find { |b| b.text.match?(/read/i) }.click

    within(".swal2-html-container") do
      find('[data-tag-key]').set("usage_status")
      find('[data-tag-value]').set("secondhand")
      click_button "Save"
    end

    expect(page).to have_content("read permission updated", wait: 10)

    policy_read_product.reload
    expect(policy_read_product.tag_conditions).to eq("usage_status" => "secondhand")

    company.clear_permissions_cache
    admin_employee.clear_permissions_cache
    admin_employee.reload

    expect(admin_employee.can?(:read, tagged_product)).to be_truthy
    expect(admin_employee.can?(:read, untagged_product)).to be_falsey
  end

  scenario "multiple tag conditions use AND logic for can? check", :js do
    product_both_tags = create(:product, company: company, branch: branch, name: "Apple Featured")
    product_both_tags.attach_tag(key: "brand", value: "Apple")
    product_both_tags.attach_tag(key: "is_featured", value: "true")

    product_brand_only = create(:product, company: company, branch: branch, name: "Apple Regular")
    product_brand_only.attach_tag(key: "brand", value: "Apple")

    product_neither = create(:product, company: company, branch: branch, name: "Other Product")

    sign_in(owner)
    visit company_permissions_path(company)

    expect(page).to have_selector('.role-section', text: "admin", wait: 20)

    admin_section = find('.role-section', text: "admin")
    resource_section = admin_section.find('.resource-section', text: 'Product')
    resource_section.all('button').find { |b| b.text.match?(/read/i) }.click

    within(".swal2-html-container") do
      find('[data-tag-key]').set("brand")
      find('[data-tag-value]').set("Apple")
      click_button "Add Condition"
      all('[data-tag-row]').last.find('[data-tag-key]').set("is_featured")
      all('[data-tag-row]').last.find('[data-tag-value]').set("true")
      click_button "Save"
    end

    expect(page).to have_content("read permission updated", wait: 10)

    policy_read_product.reload
    expect(policy_read_product.tag_conditions).to eq("brand" => "Apple", "is_featured" => "true")

    company.clear_permissions_cache
    admin_employee.clear_permissions_cache
    admin_employee.reload

    expect(admin_employee.can?(:read, product_both_tags)).to be_truthy
    expect(admin_employee.can?(:read, product_brand_only)).to be_falsey
    expect(admin_employee.can?(:read, product_neither)).to be_falsey
  end
end
