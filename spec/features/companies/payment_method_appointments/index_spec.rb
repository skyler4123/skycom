# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::PaymentMethodAppointments Management", type: :feature, js: true do
  let(:company) { create(:company).tap { |c| c.update_column(:country, 840) } }
  let(:branch) { create(:branch, company: company) }
  let(:owner) { company.user }

  # Create payment methods matching the company's country (US = 840)
  let!(:pm_cash) { create(:payment_method, name: "Cash", code: "CASH", business_type: :b2c, payment_mode: :cash, strategy: :cash, country: 840) }
  let!(:pm_qr) { create(:payment_method, name: "Mock QR", code: "MOCK_QR", business_type: :b2c, payment_mode: :qr, strategy: :mock_qr_gateway, country: 840) }
  let!(:pm_redirect) { create(:payment_method, name: "Mock Redirect", code: "MOCK_REDIRECT", business_type: :b2c, payment_mode: :redirect, strategy: :mock_redirect_gateway, country: 840) }
  let!(:pm_card) { create(:payment_method, name: "Credit Card", code: "STRIPE", business_type: :b2c, payment_mode: :redirect, strategy: :stripe_gateway, country: 840) }
  let!(:pm_vietqr) { create(:payment_method, name: "VietQR Transfer", code: "VIETQR", business_type: :b2c, payment_mode: :qr, strategy: :viet_qr_gateway, country: 840) }

  let!(:admin_role) { create(:role, company: company, name: "admin") }
  let!(:manager_role) { create(:role, company: company, name: "manager") }
  let!(:cashier_role) { create(:role, company: company, name: "cashier") }

  let!(:admin_user) { create(:user, :company_employee) }
  let!(:manager_user) { create(:user, :company_employee) }
  let!(:cashier_user) { create(:user, :company_employee) }

  let!(:admin_employee) do
    create(:employee, company: company, branch: branch, user: admin_user).tap do |e|
      RoleAppointment.find_or_create_by!(role: admin_role, appoint_to: e, company: company)
      company.clear_permissions_cache
    end
  end

  let!(:manager_employee) do
    create(:employee, company: company, branch: branch, user: manager_user).tap do |e|
      RoleAppointment.find_or_create_by!(role: manager_role, appoint_to: e, company: company)
      company.clear_permissions_cache
    end
  end

  let!(:cashier_employee) do
    create(:employee, company: company, branch: branch, user: cashier_user).tap do |e|
      RoleAppointment.find_or_create_by!(role: cashier_role, appoint_to: e, company: company)
      company.clear_permissions_cache
    end
  end

  before do
    policy_read = Seed::PolicyService.create(
      company: company,
      name: "Can read PaymentMethodAppointment",
      resource: "PaymentMethodAppointment",
      action: "read"
    )
    policy_update = Seed::PolicyService.create(
      company: company,
      name: "Can update PaymentMethodAppointment",
      resource: "PaymentMethodAppointment",
      action: "update"
    )

    PolicyAppointment.find_or_create_by!(policy: policy_read, appoint_to: admin_role, company: company).update!(workflow_status: :active)
    PolicyAppointment.find_or_create_by!(policy: policy_update, appoint_to: admin_role, company: company).update!(workflow_status: :active)
    PolicyAppointment.find_or_create_by!(policy: policy_read, appoint_to: manager_role, company: company).update!(workflow_status: :active)
    PolicyAppointment.find_or_create_by!(policy: policy_update, appoint_to: manager_role, company: company).update!(workflow_status: :active)

    company.clear_permissions_cache
  end

  def seed_client_cache
    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "branches" => [],
      "departments" => [],
      "roles" => []
    )

    payload = {
      user: JSON.parse(company.user.to_json),
      companies: [ company_data ],
      enums: {},
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  describe "authentication and authorization" do
    scenario "unauthenticated user is redirected" do
      visit company_payment_method_appointments_path(company)
      expect(page).to have_current_path("/")
    end

    scenario "unauthorized role (cashier) sees forbidden" do
      sign_in(cashier_user)
      visit company_payment_method_appointments_path(company)
      expect(page).to have_content("You are not authorized to perform this action.")
    end

    scenario "admin can view the page" do
      sign_in(admin_user)
      seed_client_cache
      visit company_payment_method_appointments_path(company)
      expect(page).to have_content("Payment Methods", wait: 10)
    end

    scenario "manager can view the page" do
      sign_in(manager_user)
      seed_client_cache
      visit company_payment_method_appointments_path(company)
      expect(page).to have_content("Payment Methods", wait: 10)
    end

    scenario "owner can view the page" do
      sign_in(owner)
      seed_client_cache
      visit company_payment_method_appointments_path(company)
      expect(page).to have_content("Payment Methods", wait: 10)
    end
  end

  describe "index page content" do
    before do
      sign_in(admin_user)
      seed_client_cache
      visit company_payment_method_appointments_path(company)
    end

    scenario "shows all payment methods matching company country" do
      expect(page).to have_content("Cash", wait: 10)
      expect(page).to have_content("Mock QR")
      expect(page).to have_content("Mock Redirect")
      expect(page).to have_content("Credit Card")
      expect(page).to have_content("VietQR Transfer")
    end

    scenario "shows status badge for each method" do
      expect(page).to have_content("Inactive", wait: 10)
    end

    scenario "each row has an edit link" do
      expect(page).to have_selector("a[href*='/edit']", count: 5, wait: 10)
    end
  end

  describe "edit page" do
    let!(:appointment) do
      pm = pm_cash
      PaymentMethodAppointment.create!(
        company: company,
        payment_method: pm,
        name: "#{pm.name} for #{company.name}",
        code: "EDIT-TEST-#{SecureRandom.hex(4).upcase}",
        business_type: :in_store,
        lifecycle_status: :inactive
      )
    end

    scenario "shows payment method details and status select" do
      sign_in(admin_user)
      seed_client_cache

      visit edit_company_payment_method_appointment_path(company, appointment)

      expect(page).to have_content("Cash", wait: 10)
      expect(page).to have_button("Save Changes")
    end

    scenario "updating status to active enables the method" do
      sign_in(admin_user)
      seed_client_cache

      visit edit_company_payment_method_appointment_path(company, appointment)

      expect(page).to have_content("Cash", wait: 10)
      page.execute_script("document.querySelector('select[name=\"payment_method_appointment[lifecycle_status]\"]').value = 'active'")
      click_button "Save Changes"

      expect(page).to have_content("Payment method updated successfully", wait: 10)
      expect(page).to have_content("Active")
    end

    scenario "updating status to active then inactive" do
      sign_in(admin_user)
      seed_client_cache

      visit edit_company_payment_method_appointment_path(company, appointment)

      expect(page).to have_content("Cash", wait: 10)
      page.execute_script("document.querySelector('select[name=\"payment_method_appointment[lifecycle_status]\"]').value = 'active'")
      click_button "Save Changes"

      expect(page).to have_content("Payment method updated successfully", wait: 10)
      expect(page).to have_content("Active")

      href = page.evaluate_script("document.querySelector('a[href*=\"/edit\"]').getAttribute('href')")
      visit href
      expect(page).to have_content("Cash", wait: 10)
      page.execute_script("document.querySelector('select[name=\"payment_method_appointment[lifecycle_status]\"]').value = 'inactive'")
      click_button "Save Changes"

      expect(page).to have_content("Payment method updated successfully", wait: 10)
      expect(page).to have_content("Inactive")
    end

    scenario "cancel returns to index" do
      sign_in(admin_user)
      seed_client_cache

      visit edit_company_payment_method_appointment_path(company, appointment)

      expect(page).to have_content("Cancel", wait: 10)
      click_link "Cancel"

      expect(page).to have_current_path(company_payment_method_appointments_path(company))
    end
  end

  describe "edge cases" do
    scenario "appointments auto-created as inactive for all matching payment methods" do
      sign_in(admin_user)
      seed_client_cache
      visit company_payment_method_appointments_path(company)

      expect(page).to have_selector("tbody tr", count: 5, wait: 10)
    end
  end
end
