# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::Pages::RetailCashier", type: :feature, js: true do
  let(:company_user) { create(:user, :company_owner) }
  let(:company) { Seed::CompanyService.new(user: company_user, country: :us, business_type: :education).tap(&:save!) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company) }
  let(:warehouse) { create(:warehouse, company: company, branch: branch) }
  let(:page_record) { create(:page, company: company, branch: branch, target_role: :retail_cashier) }

  let!(:product_a) { create(:product, company: company, branch: branch, name: "Widget Alpha") }
  let!(:product_b) { create(:product, company: company, branch: branch, name: "Widget Beta") }
  let!(:product_c) { create(:product, company: company, branch: branch, name: "Widget Gamma") }

  let!(:stock_a) do
    cat = product_a.category
    Stock.create!(company:, warehouse:, product: product_a, quantity: 10, pending: 0, category: cat,
property_mapping: cat.default_property_mapping).tap { |s| s.send(:sync_available_counter) }
  end
  let!(:stock_b) do
    cat = product_b.category
    Stock.create!(company:, warehouse:, product: product_b, quantity: 5, pending: 0, category: cat,
property_mapping: cat.default_property_mapping).tap { |s| s.send(:sync_available_counter) }
  end
  let!(:stock_c) do
    cat = product_c.category
    Stock.create!(company:, warehouse:, product: product_c, quantity: 0, pending: 0, category: cat,
property_mapping: cat.default_property_mapping).tap { |s| s.send(:sync_available_counter) }
  end

  let(:cash_pm) do
    PaymentMethod.create!(name: "Cash", code: "FE_CASH", business_type: :b2c,
      payment_mode: :cash, strategy: :cash)
  end
  let(:qr_pm) do
    PaymentMethod.create!(name: "Mock QR", code: "FE_MQR", business_type: :b2c,
      payment_mode: :qr, strategy: :mock_qr_gateway)
  end
  let!(:method_appts) do
    [
      PaymentMethodAppointment.create!(appoint_to: company, company: company, payment_method: cash_pm,
        name: "Co cash", code: "FE_CO_CASH", business_type: :in_store, lifecycle_status: :active),
      PaymentMethodAppointment.create!(appoint_to: company, company: company, payment_method: qr_pm,
        name: "Co qr", code: "FE_CO_MQR", business_type: :in_store, lifecycle_status: :active,
        merchant_number: "5555555555", merchant_name: company.name, merchant_id: "T-FE02"),
      PaymentMethodAppointment.create!(appoint_to: branch, company: company, payment_method: cash_pm,
        name: "Br cash", code: "FE_BR_CASH", business_type: :in_store, lifecycle_status: :active,
        merchant_number: "4444444444", merchant_name: company.name, merchant_id: "T-FE01"),
      PaymentMethodAppointment.create!(appoint_to: branch, company: company, payment_method: qr_pm,
        name: "Br qr", code: "FE_BR_MQR", business_type: :in_store, lifecycle_status: :active,
        merchant_number: "5555555555", merchant_name: company.name, merchant_id: "T-FE02")
    ]
  end

  before do
    sign_in(owner)
  end

  scenario "page loads and displays products gallery" do
    visit "/companies/#{company.id}/pages/#{page_record.id}/retail_cashier"

    expect(page).to have_content(/Products Gallery/i, wait: 10)
    expect(page).to have_selector('[data-action*="addToCart"]', minimum: 3, wait: 10)
    expect(page).to have_content(product_a.name)
    expect(page).to have_content(product_b.name)
    expect(page).to have_content(product_c.name)
    expect(page).to have_content("Cart is empty")
  end

  scenario "adding and removing items from cart" do
    visit "/companies/#{company.id}/pages/#{page_record.id}/retail_cashier"

    first('[data-action*="addToCart"]', wait: 10).click
    expect(page).to have_content(product_a.name)
    expect(page).to have_content("Subtotal")
    expect(page).not_to have_content("Cart is empty")

    find("button", text: /close/i).click
    expect(page).to have_content("Cart is empty")
  end

  scenario "ORDER creates pending order and switches to COMPLETE PAYMENT" do
    visit "/companies/#{company.id}/pages/#{page_record.id}/retail_cashier"

    first('[data-action*="addToCart"]', wait: 10).click

    click_button "ORDER"
    expect(page).to have_button("COMPLETE PAYMENT", wait: 10)
    expect(page).to have_button("Cancel")

    expect(Order.count).to eq(1)
    expect(Order.last.workflow_status).to eq("pending")
  end

  scenario "Cancel after ORDER returns to ORDER state" do
    visit "/companies/#{company.id}/pages/#{page_record.id}/retail_cashier"

    first('[data-action*="addToCart"]', wait: 10).click
    click_button "ORDER"
    expect(page).to have_button("COMPLETE PAYMENT", wait: 10)

    click_button "Cancel"
    expect(page).to have_button("ORDER", wait: 10)
    expect(page).not_to have_button("COMPLETE PAYMENT")

    expect(Order.count).to eq(1)
  end

  scenario "COMPLETE PAYMENT processes order and shows the receipt" do
    visit "/companies/#{company.id}/pages/#{page_record.id}/retail_cashier"

    first('[data-action*="addToCart"]', wait: 10).click
    click_button "ORDER"
    expect(page).to have_button("COMPLETE PAYMENT", wait: 10)

    click_button "COMPLETE PAYMENT"

    expect(page).to have_content(/receipt/i, wait: 10)
    expect(page).to have_content("INV-", wait: 5)
    expect(page).to have_content("Paid", wait: 5)
    expect(page).to have_content(product_a.name, wait: 5)
    expect(page).to have_button("New Sale")

    order = Order.last
    expect(order.reload.workflow_status).to eq("paid")
    expect(Invoice.where(order_id: order.id)).to be_present
    expect(Transaction.joins(:invoice).where(invoice: { order_id: order.id })).to be_present

    click_button "New Sale"
    expect(page).to have_button("ORDER", wait: 10)
    expect(page).to have_content("Cart is empty", wait: 5)
  end

  scenario "cart is locked after ORDER is placed" do
    visit "/companies/#{company.id}/pages/#{page_record.id}/retail_cashier"

    first('[data-action*="addToCart"]', wait: 10).click
    expect(page).to have_content(product_a.name)

    click_button "ORDER"
    expect(page).to have_button("COMPLETE PAYMENT", wait: 10)

    expect(page).to have_content("Qty: 1")
    expect(page).not_to have_selector('[data-action*="updateQty"]')
    expect(page).not_to have_selector("button", text: /close/i)
  end

  scenario "ORDER with insufficient stock shows error" do
    visit "/companies/#{company.id}/pages/#{page_record.id}/retail_cashier"

    all('[data-action*="addToCart"]', wait: 10).last.click
    click_button "ORDER"

    expect(page).not_to have_button("COMPLETE PAYMENT", wait: 5)
    expect(page).to have_button("ORDER")
    expect(Order.count).to eq(0)
  end

  scenario "ORDER with empty cart shows warning" do
    visit "/companies/#{company.id}/pages/#{page_record.id}/retail_cashier"

    click_button "ORDER"

    expect(page).to have_button("ORDER")
    expect(page).not_to have_button("COMPLETE PAYMENT")
    expect(Order.count).to eq(0)
  end

  scenario "shows the branch-appointed payment methods instead of hardcoded Card" do
    visit "/companies/#{company.id}/pages/#{page_record.id}/retail_cashier"

    expect(page).to have_button("Cash", wait: 10)
    expect(page).to have_button("Mock QR")
    expect(page).not_to have_button("Card")
  end

  scenario "mock QR one-click completes via websocket and shows the receipt" do
    allow(Payments::MockQrGateway).to receive(:new).and_return(
      double(call: { success: true, gateway_reference: "MOCK_QR_FE", gateway_payload: { "qr_string" => "FEQRDATA" } })
    )

    visit "/companies/#{company.id}/pages/#{page_record.id}/retail_cashier"

    first('[data-action*="addToCart"]', wait: 10).click
    click_button "Mock QR"
    click_button "ORDER"

    expect(page).to have_content("Scan to Pay", wait: 10)
    expect(page).to have_selector("#cashier-qr-container", wait: 5)
    expect(page).not_to have_button("COMPLETE PAYMENT")

    expect(Order.count).to eq(1)
    expect(Order.last.workflow_status).to eq("pending")
    expect(Transaction.last.status).to eq("pending")

    token = page.find("#cashier-qr-container")["data-transaction-token"]

    page.execute_script(
      "return fetch('/webhooks/payments/mock_qr_gateway', { method: 'POST'," \
      " headers: { 'Content-Type': 'application/json', 'X-Skycom-Bank-Signature': 'local_secure_dev_secret' }," \
      " body: JSON.stringify({ event: 'transaction.completed', data: { transaction_token: arguments[0], amount: arguments[1] } }) })" \
      ".then(r => r.status)",
      token, Transaction.last.reload.price_cents
    )

    expect(Transaction.last.reload.status).to eq("completed")
    expect(Order.last.reload.workflow_status).to eq("paid")

    page.execute_script(
      "window.WEBSOCKET.handleIncomingPublication(window.location.pathname.split('/')[2], { event: 'pos_payment_completed', id: 'sim', payload: { transaction_token: arguments[0] } })",
      token
    )

    expect(page).to have_content(/receipt/i, wait: 10)
    expect(page).to have_content("Paid", wait: 5)
    expect(page).to have_content("INV-", wait: 5)
    expect(page).to have_button("New Sale", wait: 5)

    expect(Order.last.reload.workflow_status).to eq("paid")
    expect(Transaction.last.status).to eq("completed")

    click_button "New Sale"
    expect(page).to have_button("ORDER", wait: 10)
    expect(page).to have_content("Cart is empty", wait: 5)
  end

  scenario "mock QR cancel releases stock and restores the cart" do
    allow(Payments::MockQrGateway).to receive(:new).and_return(
      double(call: { success: true, gateway_reference: "MOCK_QR_FE2", gateway_payload: { "qr_string" => "FEQRDATA2" } })
    )

    visit "/companies/#{company.id}/pages/#{page_record.id}/retail_cashier"

    first('[data-action*="addToCart"]', wait: 10).click
    click_button "Mock QR"
    click_button "ORDER"
    expect(page).to have_selector("#cashier-qr-container", wait: 10)

    click_button "Cancel"
    expect(page).to have_button("ORDER", wait: 10)
    expect(page).to have_content(product_a.name, wait: 5)
    expect(Transaction.last.status).to eq("failed")
    expect(stock_a.reload.pending).to eq(0)
  end
end
