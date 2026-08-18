# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::TopUpsController", type: :request do
  let(:company) { create(:company, country: :us, currency: :usd) }
  let(:owner_user) { company.user }
  let!(:mock_qr) { create(:billing_payment_method, :mock_qr) }
  let!(:mock_redirect) { create(:billing_payment_method, :mock_redirect) }

  before do
    get sign_in_for_test_path(email: owner_user.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET /companies/:company_id/top_ups/new" do
    it "returns country-based top-up options and b2b payment methods" do
      get "/companies/#{company.id}/top_ups/new", as: :json
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body["top_up_options"]).to eq([
        { "money_amount_cents" => 500, "credit_amount" => 500_000 },
        { "money_amount_cents" => 1_000, "credit_amount" => 1_000_000 }
      ])
      expect(body["payment_methods"].map { |m| m["strategy"] }).to include("mock_qr_gateway", "mock_redirect_gateway")
    end
  end

  describe "POST /companies/:company_id/top_ups/mock_qr_gateway" do
    before do
      allow(Payments::MockQrGateway).to receive(:new).and_return(
        double(call: { success: true, gateway_reference: "MOCK_QR_1", gateway_payload: { "qr_string" => "QRCODE123" } })
      )
    end

    it "creates the pending chain and returns the qr_string" do
      expect {
        post "/companies/#{company.id}/top_ups/mock_qr_gateway", params: { money_amount_cents: 500 }, as: :json
      }.to change(CompanyOrder, :count).by(1)
        .and change(CompanyInvoice, :count).by(1)
        .and change(CompanyTransaction, :count).by(1)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["qr_string"]).to eq("QRCODE123")

      txn = CompanyTransaction.last
      expect(txn.status).to eq("pending")
      expect(txn.gateway_reference).to start_with("TOPUP_")
      expect(txn.gateway_payload).to eq({ "qr_string" => "QRCODE123" })
      expect(txn.company_invoice.payment_status).to eq("unpaid")
      expect(txn.company_invoice.company_order.credit_amount).to eq(500_000)
    end

    it "rejects amounts outside the country's rate tiers" do
      post "/companies/#{company.id}/top_ups/mock_qr_gateway", params: { money_amount_cents: 123 }, as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to include("Unsupported top-up amount")
      expect(CompanyOrder.count).to eq(0)
    end
  end

  describe "POST /companies/:company_id/top_ups/mock_redirect_gateway" do
    before do
      allow(Payments::MockRedirectGateway).to receive(:new).and_return(
        double(call: { success: true, gateway_reference: "MOCK_SESS_1", gateway_payload: { "redirect_url" => "http://mock.local/bank/hosted-checkout?session_id=SESS_1" } })
      )
    end

    it "creates the pending chain and returns the redirect_url" do
      post "/companies/#{company.id}/top_ups/mock_redirect_gateway", params: { money_amount_cents: 1_000 }, as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["redirect_url"]).to eq("http://mock.local/bank/hosted-checkout?session_id=SESS_1")

      txn = CompanyTransaction.last
      expect(txn.status).to eq("pending")
      expect(txn.gateway_payload).to eq({ "redirect_url" => "http://mock.local/bank/hosted-checkout?session_id=SESS_1" })
      expect(txn.company_invoice.company_order.credit_amount).to eq(1_000_000)
    end
  end
end
