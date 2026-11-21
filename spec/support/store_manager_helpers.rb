# frozen_string_literal: true

# Deterministic records for Store Manager specs: paid invoices with tenders,
# real scheduled shifts + check-ins, and low stock rows.
module StoreManagerSpecHelpers
  def create_store_invoice_order(
    company:, branch:, customer: nil, employee: nil,
    channel: :click_collect, workflow_status: :paid, fulfillment_status: nil,
    total_cents: 10_000, tax_cents: 0, tender: :cash,
    cash_received_cents: nil, change_cents: 0, created_at: Time.current
  )
    customer ||= create(:customer, company: company, branch: branch)
    order = create(
      :order,
      company: company,
      branch: branch,
      customer: customer,
      employee: employee,
      workflow_status: workflow_status,
      fulfillment_channel: channel,
      fulfillment_status: fulfillment_status || (workflow_status.to_s == "completed" ? :handed_over : :unfulfilled),
      created_at: created_at
    )
    order.update_columns(discarded_at: nil, created_at: created_at)

    invoice = Invoice.create!(
      company: company,
      branch: branch,
      order: order,
      name: "Invoice #{SecureRandom.hex(4)}",
      code: "INV-#{SecureRandom.hex(4).upcase}",
      price_cents: total_cents,
      total_cents: total_cents,
      tax_cents: tax_cents,
      currency: order.currency,
      business_type: :sales,
      workflow_status: :paid,
      payment_status: :paid
    )

    payment_method = create(
      :payment_method,
      payment_mode: tender,
      strategy: tender == :cash ? :cash : :mock_qr_gateway
    )
    Transaction.create!(
      company: company,
      branch: branch,
      invoice: invoice,
      price_cents: total_cents,
      currency: order.currency,
      status: :completed,
      business_type: :standard_payment,
      payment_method: payment_method,
      cash_received_cents: cash_received_cents,
      change_cents: change_cents
    )

    [ order, invoice ]
  end

  def create_store_shift(
    company:, branch:, employee:, name: "Morning",
    starts_at:, ends_at:, status: :active, check_in_at: nil
  )
    template = create(
      :shift_template,
      company: company,
      branch: branch,
      name: name,
      start_time: starts_at.strftime("%H:%M"),
      end_time: ends_at.strftime("%H:%M")
    )
    shift = ScheduledShift.create!(
      company: company,
      branch: branch,
      employee: employee,
      shift_template: template,
      work_date: starts_at.to_date,
      expected_start_at: starts_at,
      expected_end_at: ends_at,
      status: status
    )
    AttendanceLog.create!(
      company: company,
      branch: branch,
      employee: employee,
      log_type: :check_in,
      logged_at: check_in_at || (starts_at + 2.minutes)
    )
    shift
  end

  def create_store_stock(company:, branch:, warehouse:, product:, quantity:, pending: 0, code: nil)
    stock = Seed::StockService.create(
      company: company,
      warehouse: warehouse,
      branch: branch,
      product_id: product.id,
      name: product.name,
      code: code || product.code || "SKU-#{SecureRandom.hex(3).upcase}",
      quantity: quantity,
      pending: pending,
      discarded_at: nil
    )
    stock.update!(discarded_at: nil)
    stock
  end
end

RSpec.configure do |config|
  config.include StoreManagerSpecHelpers
end
