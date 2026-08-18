# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::Billing", type: :feature, js: true do
  let(:company) { create(:company, country: :us, currency: :usd) }
  let(:owner) { company.user }

  let!(:paid_order) do
    order = create(:company_order, company: company, money_amount_cents: 500, credit_amount: 500_000)
    invoice = create(:company_invoice, company: company, company_order: order, money_amount_cents: 500, credit_amount: 500_000)
    create(:company_transaction, company: company, company_invoice: invoice,
      billing_payment_method: create(:billing_payment_method, :mock_qr),
      money_amount_cents: 500, status: :completed, gateway_reference: "TXN-FEATURE-001")
    order
  end

  let!(:pending_order) do
    create(:company_order, company: company, money_amount_cents: 1_000, credit_amount: 1_000_000, workflow_status: :pending)
  end

  before do
    company.company_wallet.add_credits!(amount: 1_500_000)

    sign_in(owner)

    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
      "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
      "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
      "branches" => [],
      "departments" => [],
      "roles" => []
    )

    payload = {
      user: JSON.parse(owner.to_json),
      companies: [ company_data ],
      enums: {},
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "shows the wallet balance" do
    visit company_billing_path(company)

    expect(page).to have_content(/credit balance/i, wait: 10)
    expect(page).to have_content("2,000,000", wait: 10)
  end

  scenario "lists order history with invoice and transaction details" do
    visit company_billing_path(company)

    expect(page).to have_content(paid_order.company_invoice.invoice_number, wait: 10)
    expect(page).to have_content("TXN-FEATURE-001", wait: 10)
    expect(page).to have_content("Mock QR", wait: 10)
    expect(page).to have_content("500,000", wait: 10)
    expect(page).to have_content(/paid/i, wait: 10)
  end

  scenario "shows pending orders without an invoice" do
    visit company_billing_path(company)

    expect(page).to have_content("No invoice", wait: 10)
    expect(page).to have_content("1,000,000", wait: 10)
  end
end
