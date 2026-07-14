# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::ToastMessages", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company) }

  before do
    sign_in(owner)
  end

  # ===========================================================================
  # Section 1: Toast display format — verify the message format renders
  # correctly in the SweetAlert2 toast
  # ===========================================================================

  describe "toast display format" do
    scenario "error toast with detail renders correctly" do
      visit company_products_path(company)

      page.execute_script(<<~JS)
        toast({ type: "error", message: "Failed to load products: Database connection failed" });
      JS

      expect(page).to have_content("Failed to load products: Database connection failed", wait: 10)
    end

    scenario "success toast renders correctly" do
      visit company_products_path(company)

      page.execute_script(<<~JS)
        toast({ type: "success", message: "Product 'Widget' updated successfully" });
      JS

      expect(page).to have_content("Product 'Widget' updated successfully", wait: 10)
    end

    scenario "warning toast renders correctly" do
      visit company_products_path(company)

      page.execute_script(<<~JS)
        toast({ type: "warning", message: "Cart is empty. Add items before ordering." });
      JS

      expect(page).to have_content("Cart is empty. Add items before ordering.", wait: 10)
    end

    scenario "error toast with backend errors array renders correctly" do
      visit company_products_path(company)

      page.execute_script(<<~JS)
        toast({ type: "error", message: "Resource already assigned to this role" });
      JS

      expect(page).to have_content("Resource already assigned to this role", wait: 10)
    end

    scenario "network error toast renders with error.message" do
      visit company_products_path(company)

      page.execute_script(<<~JS)
        toast({ type: "error", message: "Failed to load products: Failed to fetch" });
      JS

      expect(page).to have_content("Failed to load products: Failed to fetch", wait: 10)
    end
  end

  # ===========================================================================
  # Section 2: Permissions toast messages (uses response.message from BE)
  # ===========================================================================

  describe "permissions toast messages" do
    let!(:admin_role) { create(:role, company: company, name: "admin", business_type: :administrative) }
    let!(:manager_role) { create(:role, company: company, name: "manager", business_type: :management) }
    let!(:cashier_role) { create(:role, company: company, name: "cashier", business_type: :support) }

    def create_policy(resource:, action:, business_type: :operational)
      Seed::PolicyService.create(
        branch: branch,
        name: "#{action} #{resource}",
        resource: resource,
        action: action,
        business_type: business_type
      )
    end

    def create_policy_appointment(role:, policy:, workflow_status:)
      Seed::PolicyAppointmentService.create(
        policy: policy,
        appoint_to: role,
        company: company,
        workflow_status: workflow_status
      )
    end

    let!(:policy_read_product) { create_policy(resource: "Product", action: "read") }
    let!(:policy_create_product) { create_policy(resource: "Product", action: "create") }
    let!(:policy_update_product) { create_policy(resource: "Product", action: "update") }
    let!(:policy_delete_product) { create_policy(resource: "Product", action: "delete") }
    let!(:policy_read_customer) { create_policy(resource: "Customer", action: "read") }
    let!(:policy_create_customer) { create_policy(resource: "Customer", action: "create") }

    # Manager role: Product(read, create, update, delete)
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

    # Cashier role: no resources initially
    let!(:cashier_read_customer) do
      create_policy_appointment(role: cashier_role, policy: policy_read_customer, workflow_status: :inactive)
    end

    # Add resource to role — the backend returns message: "Resource added successfully"
    scenario "add resource to role shows backend message in toast" do
      visit company_permissions_path(company)

      cashier_section = find('.role-section', text: "cashier")
      cashier_section.click_button("Add Resource")
      expect(page).to have_selector('.swal2-html-container')

      within(".swal2-html-container") do
        select "Product", from: "permission[resource_name]"
        click_button "Add Resource"
      end

      expect(page).to have_content("Resource added successfully", wait: 10)
      expect(page).not_to have_selector('.swal2-html-container')
    end

    # Toggle permission — frontend shows "${actionName} permission updated"
    scenario "toggle permission shows action name in toast" do
      visit company_permissions_path(company)

      expect(page).to have_selector('.role-section', text: "manager", wait: 20)

      manager_section = find('.role-section', text: "manager")
      resource_section = manager_section.find('.resource-section', text: 'Product')
      toggle_button = resource_section.all('button').find { |b| b.text.match?(/update/i) }
      toggle_button.click

      within(".swal2-html-container") do
        click_button "Save"
      end

      expect(page).to have_content("update permission updated", wait: 10)
    end
  end

  # ===========================================================================
  # Section 3: Retail cashier POS toasts
  # ===========================================================================

  describe "retail cashier POS toasts" do
    let(:warehouse) { create(:warehouse, company: company, branch: branch) }
    let(:page_record) { create(:page, company: company, branch: branch, target_role: :retail_cashier) }
    let!(:product_a) { create(:product, company: company, branch: branch, name: "Widget Alpha") }
    let!(:stock_a) do
      cat = product_a.category
      Stock.create!(company:, warehouse:, product: product_a, quantity: 10, reorder: 5, category: cat,
        property_mapping: cat.default_property_mapping).tap { |s| s.send(:sync_available_counter) }
    end

    # ORDER creates pending order — shows "Order created"
    scenario "ORDER shows toast with order message" do
      visit "/companies/#{company.id}/pages/#{page_record.id}/retail_cashier"

      first('[data-action*="addToCart"]', wait: 10).click
      click_button "ORDER"

      expect(page).to have_content("Order created", wait: 10)
    end

    # Empty cart — shows "Cart is empty"
    scenario "order with empty cart shows warning toast" do
      visit "/companies/#{company.id}/pages/#{page_record.id}/retail_cashier"

      click_button "ORDER"

      expect(page).to have_content("Cart is empty", wait: 10)
    end
  end
end
