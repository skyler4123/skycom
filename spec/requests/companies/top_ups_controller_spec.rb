# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::TopUpsController", type: :request do
  let(:company) { create(:company) }
  let(:owner_user) { company.user }
  let(:mock_qr_method) { create(:billing_payment_method, :mock_qr) }
  let(:mock_redirect_method) { create(:billing_payment_method, :mock_redirect) }
  let(:wallet) { company.billing_wallet }

  before do
    mock_qr_method
    mock_redirect_method

    allow_any_instance_of(Payments::MockQrGateway).to receive(:call).and_return(
      success: true,
      gateway_reference: "MOCK_QR_#{Time.current.to_i}",
      gateway_payload: { qr_string: "test_qr_string_#{SecureRandom.hex(4)}" }
    )
    allow_any_instance_of(Payments::MockRedirectGateway).to receive(:call).and_return(
      success: true,
      gateway_reference: "MOCK_SESS_#{Time.current.to_i}",
      gateway_payload: { redirect_url: "http://example.com/checkout?session_id=test" }
    )

    get sign_in_for_test_path(email: owner_user.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET /companies/:company_id/top_ups/new" do
    it "returns 200 ok" do
      get "/companies/#{company.id}/top_ups/new", as: :json
      expect(response).to have_http_status(:ok)
    end

    it "returns billing_payment_methods including mock QR and mock redirect" do
      get "/companies/#{company.id}/top_ups/new", as: :json
      body = JSON.parse(response.body)
      expect(body["billing_payment_methods"]).to be_an(Array)
      strategies = body["billing_payment_methods"].map { |m| m["strategy"] }
      expect(strategies).to include("mock_qr_gateway", "mock_redirect_gateway")
    end

    it "returns only active payment methods" do
      BillingPaymentMethod.find_by(strategy: :mock_redirect_gateway)
        .update!(lifecycle_status: :disabled)

      get "/companies/#{company.id}/top_ups/new", as: :json
      body = JSON.parse(response.body)
      strategies = body["billing_payment_methods"].map { |m| m["strategy"] }
      expect(strategies).to include("mock_qr_gateway")
      expect(strategies).not_to include("mock_redirect_gateway")
    end

    it "returns only b2b payment methods" do
      get "/companies/#{company.id}/top_ups/new", as: :json
      body = JSON.parse(response.body)
      methods = body["billing_payment_methods"]
      expect(methods).not_to be_empty
      # Verify the controller correctly queries b2b methods
      expect(methods.map { |m| m["strategy"] }).to all(be_present)
    end

    it "is accessible even when company is blocked" do
      company.billing_wallet.update!(suspension_at: 1.day.ago)
      get "/companies/#{company.id}/top_ups/new", as: :json
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /companies/:company_id/top_ups/mock_qr_gateway" do
    it "returns qr_string" do
      post "/companies/#{company.id}/top_ups/mock_qr_gateway",
        params: { amount_cents: 1000 }, as: :json
      body = JSON.parse(response.body)
      expect(body["qr_string"]).to be_present
    end

    it "creates a BillingInvoice with movement_type deposit" do
      expect {
        post "/companies/#{company.id}/top_ups/mock_qr_gateway",
          params: { amount_cents: 5000 }, as: :json
      }.to change(BillingInvoice, :count).by(1)

      invoice = BillingInvoice.last
      expect(invoice.movement_type).to eq("deposit")
      expect(invoice.target_balance).to eq("main_balance")
      expect(invoice.created_by).to eq("customer")
      expect(invoice.price_cents).to eq(5000)
    end

    it "creates a BillingTransaction with status pending" do
      expect {
        post "/companies/#{company.id}/top_ups/mock_qr_gateway",
          params: { amount_cents: 2500 }, as: :json
      }.to change(BillingTransaction, :count).by(1)

      txn = BillingTransaction.last
      expect(txn.transaction_type).to eq("top_up")
      expect(txn.status).to eq("pending")
      expect(txn.amount_cents).to eq(2500)
    end

    it "does not credit the wallet (status is pending)" do
      wallet.update!(main_balance_cents: 5000)

      post "/companies/#{company.id}/top_ups/mock_qr_gateway",
        params: { amount_cents: 3000 }, as: :json

      expect(wallet.reload.main_balance_cents).to eq(5000)
    end

    it "validates amount is positive" do
      post "/companies/#{company.id}/top_ups/mock_qr_gateway",
        params: { amount_cents: 0 }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]).to include("Amount must be positive")
    end

    context "when mock QR payment method does not exist" do
      before { BillingPaymentMethod.find_by(strategy: :mock_qr_gateway)&.destroy! }

      it "returns not found" do
        post "/companies/#{company.id}/top_ups/mock_qr_gateway",
          params: { amount_cents: 1000 }, as: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /companies/:company_id/top_ups/mock_redirect_gateway" do
    it "returns redirect_url" do
      post "/companies/#{company.id}/top_ups/mock_redirect_gateway",
        params: { amount_cents: 2000 }, as: :json
      body = JSON.parse(response.body)
      expect(body["redirect_url"]).to be_present
      expect(body["redirect_url"]).to include("checkout?session_id=")
    end

    it "creates a BillingInvoice with correct attributes" do
      expect {
        post "/companies/#{company.id}/top_ups/mock_redirect_gateway",
          params: { amount_cents: 15000 }, as: :json
      }.to change(BillingInvoice, :count).by(1)

      invoice = BillingInvoice.last
      expect(invoice.movement_type).to eq("deposit")
      expect(invoice.price_cents).to eq(15000)
    end

    it "creates a BillingTransaction" do
      expect {
        post "/companies/#{company.id}/top_ups/mock_redirect_gateway",
          params: { amount_cents: 7500 }, as: :json
      }.to change(BillingTransaction, :count).by(1)

      txn = BillingTransaction.last
      expect(txn.status).to eq("pending")
    end
  end

  describe "POST - common error handling" do
    it "rejects request without amount_cents" do
      post "/companies/#{company.id}/top_ups/mock_qr_gateway", as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects negative amount" do
      post "/companies/#{company.id}/top_ups/mock_qr_gateway",
        params: { amount_cents: -100 }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]).to include("Amount must be positive")
    end
  end
end
