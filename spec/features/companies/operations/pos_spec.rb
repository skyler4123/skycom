# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::Operations::Pos", type: :feature, js: true do
  let(:company_user) { create(:user, :company_owner) }
  let(:company) { Seed::CompanyService.new(user: company_user, country: :us, business_type: :education).tap(&:save!) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company) }
  let(:warehouse) { create(:warehouse, company: company, branch: branch) }
  let(:operation_record) { create(:operation, company: company, branch: branch, operation_type: :pos) }
  let(:pos_path) { "/companies/#{company.id}/operations/pos/#{operation_record.id}?branch_id=#{branch.id}" }

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
    branch # create first: Branch#initialize_payment_methods must see no company rows yet
    [
      CompanyPaymentMethodAppointment.create!(company: company, payment_method: cash_pm,
        name: "Co cash", code: "FE_CO_CASH", business_type: :in_store, lifecycle_status: :active),
      CompanyPaymentMethodAppointment.create!(company: company, payment_method: qr_pm,
        name: "Co qr", code: "FE_CO_MQR", business_type: :in_store, lifecycle_status: :active,
        merchant_number: "5555555555", merchant_name: company.name, merchant_id: "T-FE02"),
      BranchPaymentMethodAppointment.create!(company: company, branch: branch, payment_method: cash_pm,
        name: "Br cash", code: "FE_BR_CASH", business_type: :in_store, lifecycle_status: :active,
        merchant_number: "4444444444", merchant_name: company.name, merchant_id: "T-FE01"),
      BranchPaymentMethodAppointment.create!(company: company, branch: branch, payment_method: qr_pm,
        name: "Br qr", code: "FE_BR_MQR", business_type: :in_store, lifecycle_status: :active,
        merchant_number: "5555555555", merchant_name: company.name, merchant_id: "T-FE02")
    ]
  end

  before do
    Customer.ms_clear_index!
    sign_in(owner)
  end

  after { Customer.ms_clear_index! }

  def add_to_cart(product)
    find('[data-action*="addToCart"]', text: product.name, wait: 10).click
  end

  def assign_tax(record, rate_bp: 800, name: "Sales tax", inclusive: false)
    code = create(:tax_code, company: company, name: name, rate_bp: rate_bp, is_inclusive: inclusive)
    record.update!(tax_code: code)
    code
  end

  scenario "operation screen loads and displays products gallery" do
    visit pos_path

    expect(page).to have_content(/Products Gallery/i, wait: 10)
    expect(page).to have_selector('[data-action*="addToCart"]', minimum: 3, wait: 10)
    expect(page).to have_content(product_a.name)
    expect(page).to have_content(product_b.name)
    expect(page).to have_content(product_c.name)
    expect(page).to have_content("Cart is empty")
    expect(page).to have_button("Walk-in")
    expect(page).not_to have_content(/Tab \d/)
  end

  scenario "toggles dark mode from the POS header" do
    visit pos_path
    expect(page).to have_selector("[data-darkmode-target='trigger'] svg", visible: :all, wait: 10)

    page.execute_script("localStorage.setItem('darkmode', 'false')")
    page.execute_script("document.documentElement.classList.remove('dark')")
    expect(page.evaluate_script("document.documentElement.classList.contains('dark')")).to be(false)

    find("[data-darkmode-target='trigger']", match: :first, visible: :all).click

    expect(page.evaluate_script("localStorage.getItem('darkmode')")).to eq("true")
    expect(page.evaluate_script("document.documentElement.classList.contains('dark')")).to be(true)
  end

  scenario "filters the catalog by category" do
    tech_category = Seed::CategoryService.create(company: company, name: "Tech", resource_name: "products")
    office_category = Seed::CategoryService.create(company: company, name: "Office", resource_name: "products")

    create(:product, company: company, branch: branch, name: "Tech Widget",
      category: tech_category, property_mapping: tech_category.default_property_mapping)
    create(:product, company: company, branch: branch, name: "Office Widget",
      category: office_category, property_mapping: office_category.default_property_mapping)

    visit pos_path

    click_button "Tech", wait: 10

    expect(page).to have_content("Tech Widget")
    expect(page).not_to have_content("Office Widget")
    expect(page).not_to have_content(product_a.name)

    click_button "All"

    expect(page).to have_content("Tech Widget")
    expect(page).to have_content("Office Widget")
    expect(page).to have_content(product_a.name)
  end

  scenario "fetches a customer by id and shows the membership tier" do
    customer = create(:customer, company: company, name: "Johnathan Doe")
    membership = create(:membership, company: company, name: "VIP Gold")
    customer.attach_membership(membership.code, business_type: :loyalty)

    visit pos_path

    fill_in "pos-customer-lookup", with: customer.id
    click_button "Find"

    expect(page).to have_content("Johnathan Doe", wait: 10)
    expect(page).to have_content("VIP Gold")
  end

  scenario "fetches a customer by name" do
    create(:customer, company: company, name: "Sarah Jenkins").ms_index!(true)

    visit pos_path

    fill_in "pos-customer-lookup", with: "Sarah Jenkins"
    click_button "Find"

    expect(page).to have_content("Sarah Jenkins", wait: 10)
  end

  scenario "fetches a customer by name with typo tolerance" do
    create(:customer, company: company, name: "Sarah Jenkins").ms_index!(true)

    visit pos_path

    fill_in "pos-customer-lookup", with: "Sarah Jenkns"
    click_button "Find"

    expect(page).to have_content("Sarah Jenkins", wait: 10)
  end

  scenario "fetches a customer by email" do
    create(:customer, company: company, name: "Email Customer", email: "pos.lookup@example.com").ms_index!(true)

    visit pos_path

    fill_in "pos-customer-lookup", with: "pos.lookup@example.com"
    click_button "Find"

    expect(page).to have_content("Email Customer", wait: 10)
  end

  scenario "fetches a customer by phone stored in a property slot" do
    customer = create(:customer, company: company, name: "Phone Customer")
    customer.update!(property_string_1: "555-0100")
    customer.ms_index!(true)

    visit pos_path

    fill_in "pos-customer-lookup", with: "555-0100"
    click_button "Find"

    expect(page).to have_content("Phone Customer", wait: 10)
  end

  scenario "fetches a customer by phone_number column" do
    create(:customer, company: company, name: "Phone Column Customer", phone_number: "555-0199").ms_index!(true)

    visit pos_path

    fill_in "pos-customer-lookup", with: "555-0199"
    click_button "Find"

    expect(page).to have_content("Phone Column Customer", wait: 10)
  end

  scenario "shows a warning when the customer cannot be found" do
    visit pos_path

    fill_in "pos-customer-lookup", with: "00000000-0000-0000-0000-000000000000"
    click_button "Find"

    expect(page).to have_content("Customer not found", wait: 10)
    expect(page).to have_button("Walk-in")
    expect(page).not_to have_content("VIP Gold")
  end

  scenario "adding and removing items from cart" do
    visit pos_path

    add_to_cart(product_a)
    expect(page).to have_content(product_a.name)
    expect(page).to have_content("Subtotal")
    expect(page).not_to have_content("Cart is empty")

    find("button", text: /close/i).click
    expect(page).to have_content("Cart is empty")
  end

  scenario "ORDER creates pending order and switches to COMPLETE PAYMENT" do
    visit pos_path

    add_to_cart(product_a)

    click_button "ORDER"
    expect(page).to have_button("COMPLETE PAYMENT", wait: 10)
    expect(page).to have_button("Cancel")

    expect(Order.count).to eq(1)
    expect(Order.last.workflow_status).to eq("pending")
  end

  scenario "Cancel after ORDER voids the order and returns to ORDER state" do
    visit pos_path

    add_to_cart(product_a)
    click_button "ORDER"
    expect(page).to have_button("COMPLETE PAYMENT", wait: 10)

    click_button "Cancel"
    expect(page).to have_content("Void this order?", wait: 5)
    find(".swal2-confirm").click

    expect(page).to have_button("ORDER", wait: 10)
    expect(page).not_to have_button("COMPLETE PAYMENT")

    expect(Order.count).to eq(1)
    expect(Order.last.workflow_status).to eq("cancelled")
  end

  scenario "COMPLETE PAYMENT processes order and shows the receipt" do
    visit pos_path

    add_to_cart(product_a)
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
    visit pos_path

    add_to_cart(product_a)
    expect(page).to have_content(product_a.name)

    click_button "ORDER"
    expect(page).to have_button("COMPLETE PAYMENT", wait: 10)

    expect(page).to have_content("Qty: 1")
    expect(page).not_to have_selector('[data-action*="updateQty"]')
    expect(page).not_to have_selector("button", text: /close/i)
  end

  scenario "ORDER with insufficient stock shows error" do
    visit pos_path

    add_to_cart(product_c)
    click_button "ORDER"

    expect(page).not_to have_button("COMPLETE PAYMENT", wait: 5)
    expect(page).to have_button("ORDER")
    expect(Order.count).to eq(0)
  end

  scenario "ORDER with empty cart shows warning" do
    visit pos_path

    click_button "ORDER"

    expect(page).to have_button("ORDER")
    expect(page).not_to have_button("COMPLETE PAYMENT")
    expect(Order.count).to eq(0)
  end

  scenario "shows the branch-appointed payment methods instead of hardcoded Card" do
    visit pos_path

    expect(page).to have_button("Cash", wait: 10)
    expect(page).to have_button("Mock QR")
    expect(page).not_to have_button("Card")
  end

  scenario "mock QR one-click completes via websocket and shows the receipt" do
    allow(Payments::MockQrGateway).to receive(:new).and_return(
      double(call: { success: true, gateway_reference: "MOCK_QR_FE", gateway_payload: { "qr_string" => "FEQRDATA" } })
    )

    visit pos_path

    add_to_cart(product_a)
    click_button "Mock QR"
    click_button "ORDER"
    click_button "COMPLETE PAYMENT"

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

    # Simulated Centrifugo push — the channel argument must match the subscription
    # key registered by subscribePaymentCompleted() ("company_<id>", channelName contract).
    page.execute_script(
      "window.WEBSOCKET.handleIncomingPublication(" \
      "window.WEBSOCKET.channelName('company', window.location.pathname.split('/')[2]), " \
      "{ event: 'pos_payment_completed', id: 'sim', payload: { transaction_token: arguments[0] } })",
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

  scenario "shows the configured tax on the till, invoice, and receipt" do
    company.update!(currency: :usd)
    product_a.update!(price_cents: 5_000)
    assign_tax(product_a)

    visit pos_path
    add_to_cart(product_a)

    expect(page).to have_content("Sales tax (8%)", wait: 10)
    expect(page).to have_content("$4.00")
    expect(page).to have_content("$54.00")

    click_button "ORDER"
    click_button "COMPLETE PAYMENT"

    expect(page).to have_content(/receipt/i, wait: 10)
    expect(page).to have_content("Sales tax (8%)")
    expect(page).to have_content("$4.00")

    invoice = Invoice.order(:created_at).last
    expect(invoice.tax_cents).to eq(400)
    expect(invoice.total_cents).to eq(5_400)
    expect(invoice.price_cents).to eq(5_400)
    expect(Transaction.order(:created_at).last.price_cents).to eq(5_400)
  end

  scenario "shows mixed tax-added and tax-included groups on the cart and receipt" do
    company.update!(currency: :usd)
    product_a.update!(price_cents: 5_000)
    assign_tax(product_a, name: "VAT added", rate_bp: 1_000, inclusive: false)

    service = Seed::ServiceService.create(company: company, branch: branch, name: "Included Service")
    service.update!(price_cents: 11_000)
    assign_tax(service, name: "VAT included", rate_bp: 1_000, inclusive: true)

    visit pos_path
    add_to_cart(product_a)
    find('[data-action*="addToCart"]', text: "Included Service", wait: 10).click

    expect(page).to have_content("VAT added (10%)", wait: 10)
    expect(page).to have_content("VAT included (10%) · Included", wait: 10)
    expect(page).to have_content("$165.00", wait: 10)

    click_button "ORDER"
    click_button "COMPLETE PAYMENT"

    expect(page).to have_content(/receipt/i, wait: 10)
    expect(page).to have_content("VAT added (10%)")
    expect(page).to have_content("VAT included (10%) · Included")

    invoice = Invoice.order(:created_at).last
    expect(invoice.tax_cents).to eq(1_500)
    expect(invoice.total_cents).to eq(16_500)
    expect(invoice.tax_breakdown.map { |row| row["name"] }).to contain_exactly("VAT added", "VAT included")
    expect(invoice.tax_breakdown.map { |row| row["tax_cents"] }).to contain_exactly(500, 1_000)
  end

  scenario "uses the company default tax when the product has no code" do
    company.update!(currency: :usd)
    product_a.update!(price_cents: 5_000, tax_code: nil)
    code = create(:tax_code, company: company, name: "Default VAT", rate_bp: 500)
    TaxConfig.for_company!(company).update!(default_tax_code_id: code.id)

    visit pos_path
    add_to_cart(product_a)

    expect(page).to have_content("Default VAT (5%)", wait: 10)
    expect(page).to have_content("$52.50", wait: 10)

    click_button "ORDER"
    click_button "COMPLETE PAYMENT"

    expect(page).to have_content(/receipt/i, wait: 10)
    expect(Invoice.order(:created_at).last.tax_cents).to eq(250)
  end

  scenario "hides the tax row when the configured rate is zero" do
    company.update!(currency: :usd)
    product_a.update!(price_cents: 5_000, tax_code: nil)

    visit pos_path
    add_to_cart(product_a)

    expect(page).to have_content("$50.00", wait: 10)
    expect(page).not_to have_content("Sales tax (")

    click_button "ORDER"
    click_button "COMPLETE PAYMENT"
    expect(page).to have_content(/receipt/i, wait: 10)
    expect(Invoice.order(:created_at).last.tax_cents).to eq(0)
    expect(Invoice.order(:created_at).last.total_cents).to eq(5_000)
  end

  scenario "uses the company currency instead of a hardcoded dollar sign" do
    company.update!(country: :vn, currency: :vnd)
    product_a.update!(price_cents: 50_000, tax_code: nil)

    visit pos_path
    add_to_cart(product_a)

    expect(page).to have_content("₫", wait: 10)
    expect(page).not_to have_content("$")

    click_button "ORDER"
    click_button "COMPLETE PAYMENT"
    expect(page).to have_content(/receipt/i, wait: 10)
    expect(Invoice.order(:created_at).last.currency).to eq("vnd")
    expect(Invoice.order(:created_at).last.total_cents).to eq(50_000)
  end

  scenario "switches between grid and list and remembers the choice" do
    visit pos_path

    find('button[title="List view"]', wait: 10).click
    expect(page).to have_selector('#pos-product-grid[data-view-mode="list"]', wait: 10)

    visit pos_path
    expect(page).to have_selector('#pos-product-grid[data-view-mode="list"]', wait: 10)
  end

  scenario "locks the terminal, survives refresh, and unlocks with a password" do
    visit pos_path
    add_to_cart(product_a)

    find('button[title="Lock Terminal"]', wait: 10).click
    expect(page).to have_content("Terminal locked", wait: 10)

    visit pos_path
    expect(page).to have_content("Terminal locked", wait: 10)

    find("#pos-unlock-password").set("WrongPassword@1234")
    click_button "Unlock"
    expect(page).to have_content("Incorrect password", wait: 10)
    expect(page).to have_content("Terminal locked")

    find("#pos-unlock-password").set("Password@1234")
    click_button "Unlock"

    expect(page).not_to have_content("Terminal locked", wait: 10)
    within('[data-operation-block="cart"]') do
      expect(page).to have_content(product_a.name)
    end
  end

  scenario "shows code not found without changing the cart" do
    visit pos_path

    find("#barcode-input", wait: 10).set("NOPE-404")
    find("#barcode-input").send_keys(:enter)

    expect(page).to have_content("Code not found", wait: 10)
    expect(page).to have_content("Cart is empty")
  end

  scenario "tells the cashier when the catalog is capped" do
    48.times do |index|
      create(:product, company: company, branch: branch, name: "Extra #{index} #{SecureRandom.hex(4)}")
    end

    visit pos_path

    expect(page).to have_content("Showing 50 of 51", wait: 10)
  end

  scenario "names the warehouse the stock count came from" do
    visit pos_path

    expect(page).to have_content("10 in stock · #{warehouse.name}", wait: 10)
  end

  scenario "asks before clearing the cart and clears only the active tab" do
    visit pos_path
    add_to_cart(product_a)

    find('button[title="Clear Cart"]', wait: 10).click
    expect(page).to have_content("Discard this sale?", wait: 5)
    find(".swal2-cancel").click
    expect(page).to have_content(product_a.name)

    find('button[title="Clear Cart"]').click
    expect(page).to have_content("Discard this sale?", wait: 5)
    find(".swal2-confirm").click
    expect(page).to have_content("Cart is empty", wait: 5)
  end

  scenario "restores open tabs after a refresh but not a paid sale" do
    visit pos_path
    add_to_cart(product_a)

    visit pos_path
    within('[data-operation-block="cart"]') do
      expect(page).to have_content(product_a.name, wait: 10)
    end

    click_button "ORDER"
    click_button "COMPLETE PAYMENT"
    expect(page).to have_content(/receipt/i, wait: 10)

    visit pos_path
    expect(page).to have_content("Cart is empty", wait: 10)
  end

  scenario "sells a service at its configured price" do
    company.update!(currency: :usd)
    service = Seed::ServiceService.create(company: company, branch: branch, name: "Assembly")
    service.update!(price_cents: 2_500)

    visit pos_path
    find('[data-action*="addToCart"]', text: "Assembly", wait: 10).click

    expect(page).to have_content("$25.00", wait: 10)
    click_button "ORDER"
    click_button "COMPLETE PAYMENT"

    expect(page).to have_content(/receipt/i, wait: 10)
    expect(page).to have_content("Assembly")

    line = OrderServiceAppointment.order(:created_at).last
    expect(line.unit_price.to_f).to eq(25.0)
    expect(line.total_price.to_f).to eq(25.0)
    expect(Order.last.workflow_status).to eq("paid")
  end

  scenario "applies and removes a discount code" do
    company.update!(currency: :usd)
    product_a.update!(price_cents: 5_000)
    assign_tax(product_a)
    group = Seed::DiscountGroupService.create(company: company, name: "POS Discounts", prefix: "POS",
      discount_type: :percentage, percentage: 10, campaign_status: :active)
    discount = Seed::DiscountService.create(company: company, discount_group: group, code: "POS-DISC")

    visit pos_path
    add_to_cart(product_a)
    click_button "ORDER"
    expect(page).to have_button("COMPLETE PAYMENT", wait: 10)

    find("#pos-discount-code", wait: 10).set("POS-DISC")
    click_button "Apply"

    expect(page).to have_content("POS-DISC", wait: 10)
    expect(page).to have_content("$48.60")

    click_button "COMPLETE PAYMENT"
    expect(page).to have_content(/receipt/i, wait: 10)
    expect(page).to have_content("Discount")
    invoice = Invoice.order(:created_at).last
    expect(invoice.discounts.where(status: :used).sum(:amount_cents)).to eq(500)
    expect(invoice.tax_cents).to eq(360)
    expect(invoice.total_cents).to eq(4_860)
    expect(discount.reload).to be_status_used
  end

  scenario "a bad discount code leaves the total unchanged" do
    company.update!(currency: :usd)
    product_a.update!(price_cents: 5_000)
    assign_tax(product_a)

    visit pos_path
    add_to_cart(product_a)
    click_button "ORDER"
    expect(page).to have_button("COMPLETE PAYMENT", wait: 10)

    find("#pos-discount-code", wait: 10).set("NOPE")
    click_button "Apply"

    expect(page).to have_content("$54.00", wait: 10)
    expect(page).to have_content(/not found|not valid/i)
  end

  scenario "clears the attached customer back to Walk-in" do
    customer = create(:customer, company: company, name: "Sarah Clear")
    visit pos_path

    within('[data-operation-block="customer"]') do
      find("#pos-customer-lookup").set(customer.id)
      click_button "Find"
      expect(page).to have_content("Sarah Clear", wait: 10)
      click_button "Clear"
      expect(page).to have_content("Walk-in customer", wait: 10)
    end
  end

  scenario "finds a product past the first fifty by name and adds it" do
    company.update!(currency: :usd)
    48.times do |index|
      create(:product, company: company, branch: branch, name: "Extra #{index} #{SecureRandom.hex(4)}")
    end
    hidden = create(:product, company: company, branch: branch,
      name: "ZZZ Find Me", code: "FIND-ME-51", price_cents: 1_000)
    hidden_category = hidden.category
    Stock.create!(
      company: company, warehouse: warehouse, product: hidden,
      quantity: 5, pending: 0, category: hidden_category,
      property_mapping: hidden_category.default_property_mapping
    ).tap { |record| record.send(:sync_available_counter) }
    hidden.ms_index!(true)

    visit pos_path
    find("#barcode-input", wait: 10).set("ZZZ Find Me")

    expect(page).to have_content("ZZZ Find Me", wait: 10)
    find('[data-action*="addToCart"]', text: "ZZZ Find Me").click
    within('[data-operation-block="cart"]') do
      expect(page).to have_content("ZZZ Find Me")
    end

    find("#barcode-input").set("")
    expect(page).to have_content("Showing 50 of 52", wait: 10)

    within('[data-operation-block="cart"]') do
      find('[data-action*="removeFromCart"]').click
    end
    expect(page).to have_content("Cart is empty")

    find("#barcode-input").set("FIND-ME-51")
    find("#barcode-input").send_keys(:enter)
    within('[data-operation-block="cart"]') do
      expect(page).to have_content("ZZZ Find Me", wait: 10)
    end
  end

  scenario "stops the quantity at the available stock and disables the stepper" do
    company.update!(currency: :usd)
    capped = create(:product, company: company, branch: branch, name: "Capped Widget", price_cents: 1_000)
    category = capped.category
    Stock.create!(
      company: company, warehouse: warehouse, product: capped,
      quantity: 2, pending: 0, category: category,
      property_mapping: category.default_property_mapping
    ).tap { |record| record.send(:sync_available_counter) }

    visit pos_path
    card = find('[data-action*="addToCart"]', text: "Capped Widget", wait: 10)
    card.click
    card.click
    card.click

    within('[data-operation-block="cart"]') do
      expect(page).to have_content("Capped Widget")
      expect(page).to have_content("Stock limit: 2")
      expect(page).to have_selector("button[disabled]", wait: 5)
    end
  end

  scenario "shows and sells from the branch's main warehouse pile" do
    company.update!(currency: :usd)
    main = create(:warehouse, company: company, branch: branch,
      name: "Main warehouse", business_type: :main, created_at: 2.days.ago)
    overflow = create(:warehouse, company: company, branch: branch,
      name: "Overflow", business_type: :distribution, created_at: 1.day.ago)
    product = create(:product, company: company, branch: branch,
      name: "Warehoused Widget", price_cents: 1_000)
    category = product.category
    main_stock = Stock.create!(
      company: company, warehouse: main, product: product,
      quantity: 3, pending: 0, category: category,
      property_mapping: category.default_property_mapping
    ).tap { |record| record.send(:sync_available_counter) }
    Stock.create!(
      company: company, warehouse: overflow, product: product,
      quantity: 10, pending: 0, category: category,
      property_mapping: category.default_property_mapping
    ).tap { |record| record.send(:sync_available_counter) }

    visit pos_path
    expect(page).to have_content("3 in stock · Main warehouse", wait: 10)

    find('[data-action*="addToCart"]', text: "Warehoused Widget").click
    click_button "ORDER"
    expect(page).to have_button("COMPLETE PAYMENT", wait: 10)

    expect(OrderProductAppointment.order(:created_at).last.stock_id).to eq(main_stock.id)
  end

  scenario "prints only the receipt slip" do
    company.update!(currency: :usd)
    product_a.update!(price_cents: 5_000)
    assign_tax(product_a)

    visit pos_path
    add_to_cart(product_a)
    click_button "ORDER"
    click_button "COMPLETE PAYMENT"
    expect(page).to have_content(/receipt/i, wait: 10)

    print_root = find("#pos-print-root", visible: :all)
    print_text = print_root.text(:all)
    expect(print_text).to include(product_a.name)
    expect(print_text).to include("Sales tax (8%)")
    expect(print_text).to include("$54.00")

    page.execute_script("window.__printed = false; window.print = () => { window.__printed = true }")
    click_button "Print Receipt"
    expect(page.evaluate_script("window.__printed")).to be(true)
  end

  scenario "does not claim a cash drawer is connected" do
    visit pos_path

    expect(page).not_to have_content("Open Drawer")
    expect(page).not_to have_content("Cash drawer")
  end

  scenario "mock QR cancel releases stock and restores the cart" do
    allow(Payments::MockQrGateway).to receive(:new).and_return(
      double(call: { success: true, gateway_reference: "MOCK_QR_FE2", gateway_payload: { "qr_string" => "FEQRDATA2" } })
    )

    visit pos_path

    add_to_cart(product_a)
    click_button "Mock QR"
    click_button "ORDER"
    click_button "COMPLETE PAYMENT"
    expect(page).to have_selector("#cashier-qr-container", wait: 10)

    click_button "Cancel"
    expect(page).to have_button("ORDER", wait: 10)
    expect(page).to have_content(product_a.name, wait: 5)
    expect(Transaction.last.status).to eq("failed")
    expect(stock_a.reload.pending).to eq(0)
  end
end
