# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Webhooks::Payments::MockRedirectGatewayController", type: :request do
  let(:company) { create(:company) }
  let(:wallet) { company.billing_wallet }
  let(:contract) { company.active_billing_contract }
  let(:mock_redirect_method) { create(:billing_payment_method, :mock_redirect) }
  let(:invoice) {
    create(:billing_invoice, company: company, billing_contract: contract,
           movement_type: :deposit, target_balance: :main_balance,
           price_cents: 10000, payment_status: :unpaid)
  }
  let!(:transaction) {
    create(:billing_transaction, company: company, billing_invoice: invoice,
           billing_payment_method: mock_redirect_method,
           transaction_type: :top_up, amount_cents: 10000,
           status: :pending, gateway_reference: "redirect_token_456",
           balance_before_cents: 0, balance_after_cents: 0)
  }
  let(:valid_headers) {
    { "X-Skycom-RedirectBank-Signature" => WEBHOOK_REDIRECT_PAYMENT_SECRET }
  }
  let(:valid_payload) {
    {
      bank_code: "VIET_BANK_DIRECT_2026",
      reference_code: "BANK2_AUTO_123456",
      associated_uuid: invoice.id,
      authorized_token: "redirect_token_456",
      settlement_amount: 10000,
      status: "SUCCESS_PAID",
      timestamp_epoch: Time.current.to_i
    }
  }

  before do
    mock_redirect_method
    wallet.update!(main_balance_cents: 0)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "POST /webhooks/payments/mock_redirect_gateway" do
    it "credits the wallet with the settlement amount" do
      expect {
        post "/webhooks/payments/mock_redirect_gateway",
          params: valid_payload, headers: valid_headers, as: :json
      }.to change { wallet.reload.main_balance_cents }.from(0).to(10000)
    end

    it "updates the transaction status to completed" do
      post "/webhooks/payments/mock_redirect_gateway",
        params: valid_payload, headers: valid_headers, as: :json

      expect(transaction.reload.status).to eq("completed")
    end

    it "returns status completed" do
      post "/webhooks/payments/mock_redirect_gateway",
        params: valid_payload, headers: valid_headers, as: :json

      body = JSON.parse(response.body)
      expect(body["status"]).to eq("completed")
    end

    it "updates the invoice payment_status to paid" do
      post "/webhooks/payments/mock_redirect_gateway",
        params: valid_payload, headers: valid_headers, as: :json

      expect(invoice.reload.payment_status).to eq("paid")
    end

    context "when signature is invalid" do
      it "returns unauthorized" do
        post "/webhooks/payments/mock_redirect_gateway",
          params: valid_payload,
          headers: { "X-Skycom-RedirectBank-Signature" => "wrong_secret" },
          as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when transaction is not found" do
      it "returns not found for unknown authorized_token" do
        post "/webhooks/payments/mock_redirect_gateway",
          params: { authorized_token: "nonexistent", settlement_amount: 1000 },
          headers: valid_headers, as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when missing required params" do
      it "returns 422 without authorized_token" do
        post "/webhooks/payments/mock_redirect_gateway",
          params: { settlement_amount: 5000 },
          headers: valid_headers, as: :json

        expect(response.status).to eq(422)
      end
    end

    context "when transaction is already completed" do
      before { transaction.update!(status: :completed) }

      it "returns ok and does not double-credit" do
        expect {
          post "/webhooks/payments/mock_redirect_gateway",
            params: valid_payload, headers: valid_headers, as: :json
        }.not_to(change { wallet.reload.main_balance_cents })

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["status"]).to eq("already_completed")
      end
    end
  end
end
