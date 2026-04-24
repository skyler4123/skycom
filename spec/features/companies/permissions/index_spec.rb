require "rails_helper"

RSpec.feature "Companies::Permissions Management", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:owner) { company.user }

  # Use let! to ensure roles are created before visiting the page
  let!(:admin_role) { create(:role, company: company, name: "admin", role_business_type: :administrative) }
  let!(:manager_role) { create(:role, company: company, name: "manager", role_business_type: :management) }
  let!(:cashier_role) { create(:role, company: company, name: "cashier", role_business_type: :support) }

  # Use let! for policies
  let!(:policy_read_product) { create_policy(resource: "Product", action: "read") }
  let!(:policy_create_product) { create_policy(resource: "Product", action: "create") }
  let!(:policy_update_product) { create_policy(resource: "Product", action: "update") }
  let!(:policy_delete_product) { create_policy(resource: "Product", action: "delete") }
  let!(:policy_read_order) { create_policy(resource: "Order", action: "read") }
  let!(:policy_create_order) { create_policy(resource: "Order", action: "create") }
  let!(:policy_read_customer) { create_policy(resource: "Customer", action: "read") }

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
    create(:employee, company: company, branch: branch, user: admin_user, roles: [ admin_role ]).tap do |emp|
      company.clear_permissions_cache
    end
  end

  let!(:unauthorized_user) { create(:user, :company_employee) }
  let!(:unauthorized_employee) do
    create(:employee, company: company, branch: branch, user: unauthorized_user, roles: [ manager_role ])
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

  scenario "check checkbox to activate permission" do
    sign_in(owner)
    visit company_permissions_path(company)

    expect(page).to have_selector('.role-section', text: "admin", wait: 20)

    admin_section = find('.role-section', text: "admin")
    label = admin_section.all('label').find { |l| l.has_css?('input[type="checkbox"]') && !l.find('input[type="checkbox"]').checked? }

    accept_confirm do
      label.click
    end

    expect(page).to have_selector('.role-section input[type="checkbox"][data-controller="checkbox"]:checked', wait: 10)
  end

  scenario "uncheck checkbox to deactivate permission" do
    sign_in(owner)
    visit company_permissions_path(company)

    expect(page).to have_selector('.role-section', text: "admin", wait: 20)

    admin_section = find('.role-section', text: "admin")
    checked_checkbox = admin_section.all('input[type="checkbox"][data-controller="checkbox"]:checked').first
    label = checked_checkbox.find(:xpath, '..')

    accept_confirm do
      label.click
    end

    expect(admin_section).to have_selector('input[type="checkbox"][data-controller="checkbox"]:not(:checked)', wait: 10)
  end

  scenario "checked to unchecked changes can? to return false", :js do
    company.clear_permissions_cache
    admin_employee.clear_permissions_cache
    admin_employee.reload

    expect(admin_employee.can?(:read, policy_read_product.resource.constantize)).to be_truthy

    sign_in(owner)
    visit company_permissions_path(company)

    expect(page).to have_selector('.role-section', text: "admin", wait: 20)

    admin_section = find('.role-section', text: "admin")
    checked_checkbox = admin_section.all('input[type="checkbox"][data-controller="checkbox"]:checked').first
    label = checked_checkbox.find(:xpath, '..')

    accept_confirm do
      label.click
    end

    expect(admin_section).to have_selector('input[type="checkbox"][data-controller="checkbox"]:not(:checked)', wait: 10)

    company.clear_permissions_cache
    admin_employee.clear_permissions_cache
    admin_employee.reload

    expect(admin_employee.can?(:read, policy_read_product.resource.constantize)).to be_falsey
  end

  scenario "unchecked to checked changes can? to return true", :js do
    sign_in(owner)
    visit company_permissions_path(company)

    expect(page).to have_selector('.role-section', text: "admin", wait: 20)

    admin_section = find('.role-section', text: "admin")

    policy_label = admin_section.all('label').find { |l| l.text.include?("Can create Product") }
    checkbox = policy_label.find('input[type="checkbox"]')

    accept_confirm do
      checkbox.click
    end

    expect(admin_section).to have_selector('input[type="checkbox"]:checked', wait: 10)

    company.clear_permissions_cache
    admin_employee.clear_permissions_cache
    admin_employee.reload

    target_class = policy_create_product.resource.constantize
    expect(admin_employee.can?(:create, target_class)).to be_truthy
  end

  scenario "unauthorized user sees no access message" do
    sign_in(unauthorized_user)
    visit company_permissions_path(company)

    expect(page).to have_selector('.bg-red-100', wait: 20)
    expect(page).to have_content("No Access")
    expect(page).to have_content("You don't have permission to manage permissions")
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
end
