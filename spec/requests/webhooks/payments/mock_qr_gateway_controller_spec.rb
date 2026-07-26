# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Webhooks::Payments::MockQrGatewayController", type: :request do
  let(:company) { create(:company) }
  let(:wallet) { company.billing_wallet }
  let(:contract) { company.active_billing_contract }
  let(:mock_qr_method) { create(:billing_payment_method, :mock_qr) }
  let(:invoice) {
    create(:billing_invoice, company: company, billing_contract: contract,
           movement_type: :deposit, target_balance: :main_balance,
           price_cents: 5000, payment_status: :unpaid)
  }
  let!(:transaction) {
    create(:billing_transaction, company: company, billing_invoice: invoice,
           billing_payment_method: mock_qr_method,
           transaction_type: :top_up, amount_cents: 5000,
           status: :pending, gateway_reference: "test_txn_token_123",
           balance_before_cents: 0, balance_after_cents: 0)
  }
  let(:valid_headers) {
    { "X-Skycom-Bank-Signature" => WEBHOOK_BANK_PAYMENT_SECRET }
  }
  let(:valid_payload) {
    {
      data: {
        transaction_id: "TXN_QR_123456",
        invoice_id: invoice.id,
        transaction_token: "test_txn_token_123",
        amount: 5000,
        paid_at: Time.current.rfc3339
      }
    }
  }

  before do
    mock_qr_method
    wallet.update!(main_balance_cents: 0)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "POST /webhooks/payments/mock_qr_gateway" do
    it "credits the wallet with the top-up amount" do
      expect {
        post "/webhooks/payments/mock_qr_gateway",
          params: valid_payload, headers: valid_headers, as: :json
      }.to change { wallet.reload.main_balance_cents }.from(0).to(5000)
    end

    it "updates the transaction status to completed" do
      post "/webhooks/payments/mock_qr_gateway",
        params: valid_payload, headers: valid_headers, as: :json

      expect(transaction.reload.status).to eq("completed")
    end

    it "returns status completed" do
      post "/webhooks/payments/mock_qr_gateway",
        params: valid_payload, headers: valid_headers, as: :json

      body = JSON.parse(response.body)
      expect(body["status"]).to eq("completed")
    end

    it "updates balance_after_cents on the transaction" do
      post "/webhooks/payments/mock_qr_gateway",
        params: valid_payload, headers: valid_headers, as: :json

      expect(transaction.reload.balance_after_cents).to eq(5000)
    end

    context "when signature is invalid" do
      it "returns unauthorized" do
        post "/webhooks/payments/mock_qr_gateway",
          params: valid_payload,
          headers: { "X-Skycom-Bank-Signature" => "wrong_secret" },
          as: :json

        expect(response).to have_http_status(:unauthorized)
        body = JSON.parse(response.body)
        expect(body["errors"]).to include("Invalid signature")
      end

      it "does not credit the wallet" do
        expect {
          post "/webhooks/payments/mock_qr_gateway",
            params: valid_payload,
            headers: { "X-Skycom-Bank-Signature" => "wrong_secret" },
            as: :json
        }.not_to(change { wallet.reload.main_balance_cents })
      end
    end

    context "when transaction is not found" do
      it "returns not found" do
        post "/webhooks/payments/mock_qr_gateway",
          params: {
            data: {
              transaction_token: "nonexistent_token",
              amount: 1000
            }
          },
          headers: valid_headers, as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when missing required params" do
      it "returns 422 without transaction_token" do
        post "/webhooks/payments/mock_qr_gateway",
          params: { data: { amount: 1000 } },
          headers: valid_headers, as: :json

        expect(response.status).to eq(422)
      end

      it "returns 422 without amount" do
        post "/webhooks/payments/mock_qr_gateway",
          params: { data: { transaction_token: "test" } },
          headers: valid_headers, as: :json

        expect(response.status).to eq(422)
      end
    end

    context "when transaction is already completed" do
      before { transaction.update!(status: :completed) }

      it "returns ok without changing wallet" do
        expect {
          post "/webhooks/payments/mock_qr_gateway",
            params: valid_payload, headers: valid_headers, as: :json
        }.not_to(change { wallet.reload.main_balance_cents })

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["status"]).to eq("already_completed")
      end
    end
  end
end
