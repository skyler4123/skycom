# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::OrdersController#receipt", type: :request do
  let(:company_user) { create(:user, :company_owner) }
  let(:company) { Seed::CompanyService.new(user: company_user, country: :us, business_type: :education).tap(&:save!) }
  let(:branch) { create(:branch, company: company, name: "Downtown") }
  let(:customer) { create(:customer, company: company) }
  let(:cashier) { create(:employee, company: company, name: "Casey Cashier") }
  let(:product) { create(:product, company: company, name: "Receipt Widget") }
  let(:order) do
    create(:order, company: company, branch: branch, customer: customer,
      workflow_status: :pending, currency: :usd, employee: cashier)
  end
  let!(:item) do
    OrderProductAppointment.create!(order: order, product: product, company: company,
      name: product.name, quantity: 2, unit_price: 50.0, total_price: 100.0)
  end
  let!(:invoice) do
    Invoice.create!(company_id: company.id, branch_id: branch.id, order_id: order.id,
      name: "Invoice for Order #{order.id}", code: "INV-RCPT-001",
      price_cents: 10_800, tax_cents: 800, total_cents: 10_800,
      currency: order.currency, business_type: :sales,
      workflow_status: :paid, payment_status: :paid,
      metadata: { "tax_breakdown" => [
        { "name" => "Sales tax", "rate_bp" => 800, "inclusive" => false,
          "taxable_cents" => 10_000, "tax_cents" => 800 }
      ] })
  end
  let!(:txn) do
    cash_pm = PaymentMethod.create!(name: "Cash Rcpt", code: "RCPT_CASH", business_type: :b2c,
      payment_mode: :cash, strategy: :cash)
    Transaction.create!(company_id: company.id, branch_id: branch.id, invoice_id: invoice.id,
      price_cents: 10_800, currency: order.currency, status: :completed,
      business_type: :standard_payment, payment_method_id: cash_pm.id,
      gateway_reference: "POS_#{SecureRandom.hex(8)}",
      cash_received_cents: 12_000, change_cents: 1_200)
  end

  before { get sign_in_for_test_path(email: company_user.email) }

  it "returns the receipt for a paid order with the money record in cents" do
    get "/companies/#{company.id}/orders/#{order.id}/receipt", as: :json

    expect(response).to have_http_status(:ok)
    receipt = JSON.parse(response.body)["receipt"]

    aggregate_failures do
      expect(receipt["invoice_code"]).to eq("INV-RCPT-001")
      expect(receipt["payment_status"]).to eq("paid")
      expect(receipt["branch_name"]).to eq("Downtown")
      expect(receipt["cashier_name"]).to eq("Casey Cashier")
      expect(receipt["currency"]).to eq("usd")
      expect(receipt["items"]).to eq([
        { "name" => "Receipt Widget", "quantity" => 2, "unit_price_cents" => 5_000,
          "total_cents" => 10_000, "tax_cents" => 0, "tax_name" => nil,
          "tax_rate_bp" => 0, "tax_inclusive" => false, "kind" => "product" }
      ])
      expect(receipt["subtotal_cents"]).to eq(10_000)
      expect(receipt["discount_cents"]).to eq(0)
      expect(receipt["tax_cents"]).to eq(800)
      expect(receipt["tax_lines"]).to contain_exactly(
        include("name" => "Sales tax", "rate_bp" => 800, "inclusive" => false, "tax_cents" => 800)
      )
      expect(receipt).not_to have_key("tax_rate_bp")
      expect(receipt).not_to have_key("tax_name")
      expect(receipt["total_cents"]).to eq(10_800)
      expect(receipt["payment_method_name"]).to eq("Cash Rcpt")
      expect(receipt["cash_received_cents"]).to eq(12_000)
      expect(receipt["change_cents"]).to eq(1_200)
    end
  end

  it "does not invent tax for a legacy invoice without a snapshot" do
    invoice.update_columns(price_cents: 10_000, tax_cents: 0, total_cents: 10_000, metadata: {})
    txn.update_columns(price_cents: 10_000, metadata: {})

    get "/companies/#{company.id}/orders/#{order.id}/receipt", as: :json

    receipt = JSON.parse(response.body)["receipt"]
    expect(receipt["subtotal_cents"]).to eq(10_000)
    expect(receipt["tax_cents"]).to eq(0)
    expect(receipt["tax_lines"]).to eq([])
    expect(receipt["total_cents"]).to eq(10_000)
    expect(receipt["cash_received_cents"]).to be_nil
    expect(receipt["change_cents"]).to be_nil
  end

  it "falls back to item sums when no invoice exists yet" do
    invoice.destroy
    txn.destroy
    item.update!(tax_name: "Sales tax", tax_rate_bp: 800, tax_inclusive: false)

    get "/companies/#{company.id}/orders/#{order.id}/receipt", as: :json

    expect(response).to have_http_status(:ok)
    receipt = JSON.parse(response.body)["receipt"]
    expect(receipt["subtotal_cents"]).to eq(10_000)
    expect(receipt["tax_cents"]).to eq(800)
    expect(receipt["total_cents"]).to eq(10_800)
    expect(receipt["invoice_code"]).to be_nil
  end

  it "returns 404 for an unknown order" do
    get "/companies/#{company.id}/orders/00000000-0000-0000-0000-000000000000/receipt", as: :json
    expect(response).to have_http_status(:not_found)
  end

  it "returns 404 for another company's order" do
    other = Seed::CompanyService.new(user: create(:user, :company_owner), country: :us, business_type: :education).tap(&:save!)
    other_order = create(:order, company: other, customer: create(:customer, company: other))

    get "/companies/#{company.id}/orders/#{other_order.id}/receipt", as: :json
    expect(response).to have_http_status(:not_found)
  end
end
