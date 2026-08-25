# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Webhooks::Payments::MockQrGatewayController", type: :request do
  let(:company) { create(:company, country: :us, currency: :usd) }
  let!(:order) { create(:company_order, company: company, money_amount_cents: 500, credit_amount: 500_000) }
  let!(:invoice) { create(:company_invoice, company: company, company_order: order, money_amount_cents: 500, credit_amount: 500_000) }
  let!(:txn) do
    create(:company_transaction, company: company, company_invoice: invoice,
      company_payment_method: create(:company_payment_method, :mock_qr),
      money_amount_cents: 500, status: :pending, gateway_reference: "TOPUP_ABC123")
  end

  let(:valid_payload) do
    {
      event: "transaction.completed",
      data: { transaction_id: "TXN_QR_1", invoice_id: invoice.id, transaction_token: txn.gateway_reference, amount: 500 }
    }
  end

  before do
    allow(WEBSOCKET).to receive(:publish_event)
  end

  def post_webhook(payload, signature: WEBHOOK_BANK_PAYMENT_SECRET)
    post "/webhooks/payments/mock_qr_gateway", params: payload.to_json,
      headers: { "Content-Type" => "application/json", "X-Skycom-Bank-Signature" => signature }
  end

  describe "signature validation" do
    it "rejects an invalid signature" do
      post_webhook(valid_payload, signature: "wrong")
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "transaction lookup" do
    it "returns 404 for an unknown transaction token" do
      post_webhook(valid_payload.merge(data: valid_payload[:data].merge(transaction_token: "NOPE")))
      expect(response).to have_http_status(:not_found)
    end

    it "rejects a missing token or amount" do
      post_webhook(valid_payload.merge(data: { transaction_token: txn.gateway_reference }))
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects an amount that does not match the transaction" do
      post_webhook(valid_payload.merge(data: valid_payload[:data].merge(amount: 999)))
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to include("Amount mismatch")
    end
  end

  describe "completion" do
    it "completes the transaction and fires the credit chain" do
      expect {
        post_webhook(valid_payload)
      }.to change { txn.reload.status }.from("pending").to("completed")
        .and change { invoice.reload.payment_status }.from("unpaid").to("paid")
        .and change { order.reload.workflow_status }.from("pending").to("completed")
        .and change { company.company_wallet.reload.main_credit_balance }.by(500_000)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["status"]).to eq("completed")
    end

    it "publishes the top_up_completed websocket event" do
      post_webhook(valid_payload)

      expect(WEBSOCKET).to have_received(:publish_event).with(
        channel: WEBSOCKET.company_channel(company.id),
        event_key: :top_up_completed,
        data: { amount_cents: 500, transaction_id: txn.id }
      )
    end

    it "is idempotent when the transaction is already completed" do
      txn.update!(status: :completed)
      wallet_before = company.company_wallet.reload.main_credit_balance

      post_webhook(valid_payload)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["status"]).to eq("already_completed")
      expect(company.company_wallet.reload.main_credit_balance).to eq(wallet_before)
      expect(CompanyWalletLog.count).to eq(1)
    end
  end

  describe "pos transaction lookup" do
    let(:branch) { create(:branch, company: company) }
    let(:customer) { create(:customer, company: company) }
    let(:pos_order) { create(:order, company: company, branch: branch, customer: customer, workflow_status: :pending) }
    let!(:pos_invoice) do
      Invoice.create!(company_id: company.id, branch_id: branch.id, order_id: pos_order.id,
        name: "POS Invoice #{SecureRandom.hex(4)}", code: "POSWH-#{SecureRandom.hex(4)}",
        price_cents: 5000, currency: pos_order.currency, business_type: :sales)
    end
    let!(:pos_txn) do
      Transaction.create!(company_id: company.id, branch_id: branch.id, invoice_id: pos_invoice.id,
        price_cents: 5000, currency: order.currency, status: :pending,
        business_type: :standard_payment, gateway_reference: "POS_WEBHOOK1")
    end

    let(:pos_payload) do
      {
        event: "transaction.completed",
        data: { transaction_id: "TXN_QR_POS", invoice_id: pos_invoice.id,
                transaction_token: pos_txn.gateway_reference, amount: 5000 }
      }
    end

    it "completes the pos transaction and pays the order" do
      expect {
        post_webhook(pos_payload)
      }.to change { pos_txn.reload.status }.from("pending").to("completed")
        .and change { pos_invoice.reload.payment_status }.from("unpaid").to("paid")
        .and change { pos_order.reload.workflow_status }.from("pending").to("paid")

      expect(response).to have_http_status(:ok)
    end

    it "publishes pos_payment_completed" do
      post_webhook(pos_payload)

      expect(WEBSOCKET).to have_received(:publish_event).with(
        channel: WEBSOCKET.company_channel(company.id),
        event_key: :pos_payment_completed,
        data: hash_including(transaction_token: pos_txn.gateway_reference, order_id: pos_order.id)
      )
    end

    it "rejects mismatched amounts" do
      post_webhook(pos_payload.merge(data: pos_payload[:data].merge(amount: 999)))
      expect(response).to have_http_status(:unprocessable_content)
      expect(pos_txn.reload.status).to eq("pending")
    end

    it "no-ops when the payment was already cancelled" do
      pos_txn.update!(status: :failed)

      post_webhook(pos_payload)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["status"]).to eq("failed")
      expect(pos_order.reload.workflow_status).to eq("pending")
    end
  end
end
