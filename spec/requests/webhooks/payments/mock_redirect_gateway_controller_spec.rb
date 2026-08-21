# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Webhooks::Payments::MockRedirectGatewayController", type: :request do
  let(:company) { create(:company, country: :us, currency: :usd) }
  let!(:order) { create(:company_order, company: company, money_amount_cents: 1_000, credit_amount: 1_000_000) }
  let!(:invoice) { create(:company_invoice, company: company, company_order: order, money_amount_cents: 1_000, credit_amount: 1_000_000) }
  let!(:txn) do
    create(:company_transaction, company: company, company_invoice: invoice,
      company_payment_method: create(:company_payment_method, :mock_redirect),
      money_amount_cents: 1_000, status: :pending, gateway_reference: "TOPUP_XYZ789")
  end

  let(:valid_payload) do
    {
      bank_code: "VIET_BANK_DIRECT_2026",
      reference_code: "BANK2_AUTO_1",
      associated_uuid: invoice.id,
      authorized_token: txn.gateway_reference,
      settlement_amount: 1_000,
      status: "SUCCESS_PAID"
    }
  end

  before do
    allow(WEBSOCKET).to receive(:publish_event)
  end

  def post_webhook(payload, signature: WEBHOOK_REDIRECT_PAYMENT_SECRET)
    post "/webhooks/payments/mock_redirect_gateway", params: payload.to_json,
      headers: { "Content-Type" => "application/json", "X-Skycom-RedirectBank-Signature" => signature }
  end

  describe "signature validation" do
    it "rejects an invalid signature" do
      post_webhook(valid_payload, signature: "wrong")
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "completion" do
    it "completes the transaction and fires the credit chain" do
      expect {
        post_webhook(valid_payload)
      }.to change { txn.reload.status }.from("pending").to("completed")
        .and change { invoice.reload.payment_status }.from("unpaid").to("paid")
        .and change { order.reload.workflow_status }.from("pending").to("completed")
        .and change { company.company_wallet.reload.main_credit_balance }.by(1_000_000)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["status"]).to eq("completed")
    end

    it "publishes the top_up_completed websocket event" do
      post_webhook(valid_payload)

      expect(WEBSOCKET).to have_received(:publish_event).with(
        channel: WEBSOCKET.company_channel(company.id),
        event_key: :top_up_completed,
        data: { amount_cents: 1_000, transaction_id: txn.id }
      )
    end

    it "returns 404 for an unknown authorized token" do
      post_webhook(valid_payload.merge(authorized_token: "NOPE"))
      expect(response).to have_http_status(:not_found)
    end

    it "rejects a settlement amount that does not match" do
      post_webhook(valid_payload.merge(settlement_amount: 999))
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to include("Amount mismatch")
    end
  end
end
