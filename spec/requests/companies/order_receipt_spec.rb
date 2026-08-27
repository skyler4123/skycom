# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::OrdersController#receipt", type: :request do
  let(:company_user) { create(:user, :company_owner) }
  let(:company) { Seed::CompanyService.new(user: company_user, country: :us, business_type: :education).tap(&:save!) }
  let(:branch) { create(:branch, company: company) }
  let(:customer) { create(:customer, company: company) }
  let(:product) { create(:product, company: company, name: "Receipt Widget") }
  let(:order) { create(:order, company: company, branch: branch, customer: customer, workflow_status: :pending) }
  let!(:item) do
    OrderAppointment.create!(order: order, appoint_to: product, company: company,
      name: product.name, quantity: 2, unit_price: 50.0, total_price: 100.0)
  end
  let!(:invoice) do
    Invoice.create!(company_id: company.id, branch_id: branch.id, order_id: order.id,
      name: "Invoice for Order #{order.id}", code: "INV-RCPT-001",
      price_cents: 10_000, currency: order.currency, business_type: :sales,
      workflow_status: :paid, payment_status: :paid)
  end
  let!(:txn) do
    cash_pm = PaymentMethod.create!(name: "Cash Rcpt", code: "RCPT_CASH", business_type: :b2c,
      payment_mode: :cash, strategy: :cash)
    Transaction.create!(company_id: company.id, branch_id: branch.id, invoice_id: invoice.id,
      price_cents: 10_000, currency: order.currency, status: :completed,
      business_type: :standard_payment, payment_method_id: cash_pm.id,
      gateway_reference: "POS_#{SecureRandom.hex(8)}")
  end

  before { get sign_in_for_test_path(email: company_user.email) }

  it "returns the receipt for a paid order" do
    get "/companies/#{company.id}/orders/#{order.id}/receipt", as: :json

    expect(response).to have_http_status(:ok)
    receipt = JSON.parse(response.body)["receipt"]

    aggregate_failures do
      expect(receipt["invoice_code"]).to eq("INV-RCPT-001")
      expect(receipt["payment_status"]).to eq("paid")
      expect(receipt["items"]).to eq([
        { "name" => "Receipt Widget", "quantity" => 2, "unit_price" => 50.0, "total_price" => 100.0 }
      ])
      expect(receipt["subtotal"]).to eq(100.0)
      expect(receipt["tax"]).to eq(10.0)
      expect(receipt["total"]).to eq(110.0)
      expect(receipt["payment_method_name"]).to eq("Cash Rcpt")
    end
  end

  it "falls back to item sums when no invoice exists yet" do
    invoice.destroy
    txn.destroy

    get "/companies/#{company.id}/orders/#{order.id}/receipt", as: :json

    expect(response).to have_http_status(:ok)
    receipt = JSON.parse(response.body)["receipt"]
    expect(receipt["subtotal"]).to eq(100.0)
    expect(receipt["total"]).to eq(110.0)
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
