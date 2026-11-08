# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Mobile POS", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:user) { company.user }
  let(:branch) { create(:branch, company: company, name: "Downtown Branch") }
  let!(:operation_record) do
    create(
      :operation,
      company: company,
      branch: branch,
      name: "Front Counter",
      operation_type: :pos
    )
  end
  let!(:product) { create(:product, company: company, branch: branch, name: "Widget Alpha") }
  let(:pos_path) do
    "/mobile/companies/#{company.id}/operations/pos/#{operation_record.id}?branch_id=#{branch.id}"
  end

  before do
    sign_in(user)
  end

  scenario "loads the POS shell and hydrates the catalog" do
    visit pos_path

    expect(page).to have_content(/Products Gallery/i, wait: 10)
    expect(page).to have_content(product.name, wait: 10)
    expect(page).to have_content("Cart is empty", wait: 5)
  end

  scenario "opens POS from the mobile operations list" do
    visit mobile_company_operations_path(company)

    click_link "Open POS"

    expect(page).to have_current_path(pos_path, wait: 10)
    expect(page).to have_content(/Products Gallery/i, wait: 10)
  end

  scenario "adds a product to the cart" do
    visit pos_path

    find('[data-action*="addToCart"]', text: product.name, wait: 10).click

    expect(page).not_to have_content("Cart is empty", wait: 5)
    expect(page).to have_content("Subtotal", wait: 5)
  end

  scenario "toggles dark mode from the POS header" do
    visit pos_path

    expect(page).to have_selector("[data-darkmode-target='trigger'] svg", visible: :all, wait: 10)
    page.execute_script("localStorage.setItem('darkmode', 'false')")
    page.execute_script("document.documentElement.classList.remove('dark')")

    find("[data-darkmode-target='trigger']", match: :first, visible: :all).click

    expect(page.evaluate_script("localStorage.getItem('darkmode')")).to eq("true")
    expect(page.evaluate_script("document.documentElement.classList.contains('dark')")).to be(true)
  end

  scenario "stacks the order panel under the catalog on a portrait tablet" do
    page.driver.browser.manage.window.resize_to(768, 1024)
    visit pos_path

    expect(page).to have_content(/Products Gallery/i, wait: 10)
    catalog = find("section", text: /Products Gallery/i)
    order_panel = find("aside")

    expect(order_panel.native.rect.y).to be > catalog.native.rect.y
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end

  scenario "shows the order panel beside the catalog on a landscape tablet" do
    page.driver.browser.manage.window.resize_to(1280, 800)
    visit pos_path

    expect(page).to have_content(/Products Gallery/i, wait: 10)
    catalog = find("section", text: /Products Gallery/i)
    order_panel = find("aside")

    expect(order_panel.native.rect.x).to be > catalog.native.rect.x
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end

  scenario "does not show Open POS for non-POS operations" do
    create(:operation, company: company, branch: branch, name: "Booking Desk", operation_type: :booking)

    visit mobile_company_operations_path(company)

    within("section", text: "Booking Desk") do
      expect(page).to have_content("Booking Desk")
      expect(page).not_to have_link("Open POS")
    end
  end

  scenario "redirects when the POS has no active appointment" do
    BranchOperationAppointment.find_by!(operation: operation_record).update!(workflow_status: :inactive)

    visit pos_path

    expect(page).to have_current_path(mobile_company_operations_path(company), wait: 10)
    expect(page).to have_content("No active operation found for this location.")
  end

  context "with stock and a cash payment method" do
    let(:warehouse) { create(:warehouse, company: company, branch: branch) }
    let!(:stock) do
      category = product.category
      Stock.create!(
        company: company,
        warehouse: warehouse,
        product: product,
        quantity: 10,
        pending: 0,
        category: category,
        property_mapping: category.default_property_mapping
      ).tap { |record| record.send(:sync_available_counter) }
    end
    let(:cash_payment_method) do
      PaymentMethod.create!(
        name: "Cash",
        code: "MOBILE_CASH",
        business_type: :b2c,
        payment_mode: :cash,
        strategy: :cash,
        country: company.country
      )
    end
    let!(:payment_method_appointments) do
      CompanyPaymentMethodAppointment.create!(
        company: company,
        payment_method: cash_payment_method,
        name: "Co cash",
        code: "MOBILE_CO_CASH",
        business_type: :in_store,
        lifecycle_status: :active
      )

      BranchPaymentMethodAppointment.create!(
        company: company,
        branch: branch,
        payment_method: cash_payment_method,
        name: "Br cash",
        code: "MOBILE_BR_CASH",
        business_type: :in_store,
        lifecycle_status: :active
      )
    end

    scenario "completes an order and shows the receipt" do
      visit pos_path

      find('[data-action*="addToCart"]', text: product.name, wait: 10).click
      click_button "ORDER"

      expect(page).to have_button("COMPLETE PAYMENT", wait: 10)
      click_button "COMPLETE PAYMENT"

      expect(page).to have_content(/receipt/i, wait: 10)
      expect(page).to have_content("INV-", wait: 10)
      expect(page).to have_button("New Sale", wait: 5)
      expect(Order.last.workflow_status).to eq("paid")
    end
  end
end
