# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::BillingController", type: :request do
  let(:company) { create(:company) }
  let(:owner_user) { company.user }
  let(:contract) { company.active_billing_contract }

  before do
    get sign_in_for_test_path(email: owner_user.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET /companies/:company_id/billing" do
    it "returns 200 ok" do
      get "/companies/#{company.id}/billing", as: :json
      expect(response).to have_http_status(:ok)
    end

    it "returns company info with lifecycle_status" do
      get "/companies/#{company.id}/billing", as: :json
      body = JSON.parse(response.body)
      expect(body["company"]["lifecycle_status"]).to eq("active")
    end

    it "returns outstanding unpaid invoices" do
      create(:billing_invoice, company: company, billing_contract: contract, price_cents: 1500)
      get "/companies/#{company.id}/billing", as: :json
      body = JSON.parse(response.body)
      expect(body["invoices"].size).to eq(1)
      expect(body["invoices"].first["price_cents"]).to eq(1500)
    end

    it "returns wallet balances" do
      company.update!(main_balance_cents: 10_000)
      get "/companies/#{company.id}/billing", as: :json
      body = JSON.parse(response.body)
      expect(body["wallet"]["main_balance_cents"]).to eq(10_000)
    end

    it "is accessible even when access is blocked" do
      company.update!(suspension_at: 1.day.ago)
      get "/companies/#{company.id}/billing", as: :json
      expect(response).to have_http_status(:ok)
    end

    it "returns billing_contract data" do
      get "/companies/#{company.id}/billing", as: :json
      body = JSON.parse(response.body)
      expect(body["billing_contract"]).to be_present
      expect(body["billing_contract"]["contract_type"]).to be_present
      expect(body["billing_contract"]["included_allowance"]).to be_a(Hash)
      expect(body["billing_contract"]["unit_prices"]).to be_a(Hash)
    end

    it "returns wallet with total_cents" do
      company.update!(main_balance_cents: 10_000, promo_balance_cents: 5_000)
      get "/companies/#{company.id}/billing", as: :json
      body = JSON.parse(response.body)
      expect(body["wallet"]["total_cents"]).to eq(15_000)
    end

    it "returns daily_metric_totals" do
      get "/companies/#{company.id}/billing", as: :json
      body = JSON.parse(response.body)
      expect(body["daily_metric_totals"]).to be_a(Hash)
    end

    it "returns catalog_addon_features list" do
      get "/companies/#{company.id}/billing", as: :json
      body = JSON.parse(response.body)
      expect(body["catalog_addon_features"]).to be_an(Array)
    end

    it "returns estimate with days_remaining" do
      get "/companies/#{company.id}/billing", as: :json
      body = JSON.parse(response.body)
      expect(body["estimate"]).to be_present
      expect(body["estimate"]["days_remaining"]).to be >= 0
    end

    it "returns company is_accessible flag" do
      get "/companies/#{company.id}/billing", as: :json
      body = JSON.parse(response.body)
      expect(body["company"]["is_accessible"]).to be_in([ true, false ])
    end
  end

  describe "POST /companies/:company_id/billing/pay_all" do
    context "when no outstanding invoices" do
      it "returns success message" do
        post "/companies/#{company.id}/billing/pay_all", as: :json
        body = JSON.parse(response.body)
        expect(body["message"]).to eq("No outstanding invoices.")
        expect(body["remaining_cents"]).to eq(0)
      end
    end

    context "when wallet covers all invoices" do
      before do
        # Create invoice with zero balance (no auto-settlement),
        # then set balance via update_columns (bypasses after_update auto-settle
        # on the Company + doesn't refresh the cache). The pay_all action reloads
        # via with_lock inside SettlementService, so it sees the fresh DB value.
        create(:billing_invoice, company: company, billing_contract: contract, price_cents: 1500)
        company.update_columns(main_balance_cents: 50_000)
      end

      it "pays all invoices" do
        post "/companies/#{company.id}/billing/pay_all", as: :json
        expect(BillingInvoice.last.payment_status).to eq("paid")
      end

      it "returns paid_count" do
        post "/companies/#{company.id}/billing/pay_all", as: :json
        body = JSON.parse(response.body)
        expect(body["paid_count"]).to eq(1)
      end

      it "returns reactivated status" do
        company.update_columns(lifecycle_status: Company.lifecycle_statuses[:suspended], suspension_at: 1.day.ago)
        post "/companies/#{company.id}/billing/pay_all", as: :json
        body = JSON.parse(response.body)
        expect(body["reactivated"]).to be_truthy
      end

      it "returns remaining_cents = 0" do
        post "/companies/#{company.id}/billing/pay_all", as: :json
        body = JSON.parse(response.body)
        expect(body["remaining_cents"]).to eq(0)
      end
    end

    context "when wallet is insufficient" do
      before do
        create(:billing_invoice, company: company, billing_contract: contract, price_cents: 50_000)
      end

      it "returns paid_count = 0" do
        post "/companies/#{company.id}/billing/pay_all", as: :json
        body = JSON.parse(response.body)
        expect(body["paid_count"]).to eq(0)
      end

      it "returns remaining_cents > 0" do
        post "/companies/#{company.id}/billing/pay_all", as: :json
        body = JSON.parse(response.body)
        expect(body["remaining_cents"]).to eq(50_000)
      end

      it "does not mark company as reactivated" do
        company.update_columns(lifecycle_status: Company.lifecycle_statuses[:suspended], suspension_at: 1.day.ago)
        post "/companies/#{company.id}/billing/pay_all", as: :json
        body = JSON.parse(response.body)
        expect(body["reactivated"]).to be_falsey
      end
    end
  end
end
