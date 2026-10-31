# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::Dashboards", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:company) { create(:company, business_type: :retail, name: "Dashboard Spec Co") }
  let(:owner_user) { company.user }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET /companies/:id/dashboards" do
    context "when signed in as the owner" do
      before { get sign_in_for_test_path(email: owner_user.email) }

      it "returns the HTML shell" do
        get company_dashboards_path(company)

        expect(response).to have_http_status(:ok)
      end

      it "returns the financial dashboard payload" do
        get company_dashboards_path(company, format: :json)

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json.dig("permissions", "can_view_financials")).to be(true)
        expect(json["kpis"]).to include("revenue_cents", "gross_margin_pct", "orders_count")
        expect(json).to include("wallet", "trend", "revenue_mix", "top_customers")
        expect(json).to include("company", "attention", "recent_orders", "staff_today", "upcoming_events")
      end
    end

    context "when signed in as an employee without Invoice read" do
      let(:employee_user) { create(:user, :company_employee) }
      let!(:employee) { create(:employee, company: company, user: employee_user, lifecycle_status: :active) }

      before do
        employee.clear_permissions_cache
        company.clear_permissions_cache
        get sign_in_for_test_path(email: employee_user.email)
      end

      it "returns the operational payload without financial data" do
        get company_dashboards_path(company, format: :json)

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json.dig("permissions", "can_view_financials")).to be(false)
        expect(json["kpis"]).to include("orders_count", "low_stock_count", "pending_approvals_count")
        expect(json["kpis"]).not_to have_key("revenue_cents")
        expect(json).not_to have_key("wallet")
        expect(json).not_to have_key("trend")
        expect(json["attention"]["overdue_invoices"]).to eq([])
        expect(json["recent_orders"].first&.fetch("total_cents", nil)).to be_nil
      end
    end
  end

  describe "caching" do
    before { get sign_in_for_test_path(email: owner_user.email) }

    it "reuses the payload for repeat requests within five minutes" do
      allow(Dashboards::OverviewService).to receive(:call).and_call_original

      get company_dashboards_path(company, format: :json)
      get company_dashboards_path(company, format: :json)

      expect(Dashboards::OverviewService).to have_received(:call).once
    end

    it "keeps financial and operational payloads in separate cache entries" do
      employee_user = create(:user, :company_employee)
      create(:employee, company: company, user: employee_user, lifecycle_status: :active)
      allow(Dashboards::OverviewService).to receive(:call).and_call_original

      get company_dashboards_path(company, format: :json)

      get sign_in_for_test_path(email: employee_user.email)
      get company_dashboards_path(company, format: :json)

      expect(Dashboards::OverviewService).to have_received(:call).twice
    end

    it "recomputes after the five-minute cache expires" do
      allow(Dashboards::OverviewService).to receive(:call).and_call_original

      travel_to(Time.zone.local(2026, 10, 31, 9, 0, 0)) do
        get company_dashboards_path(company, format: :json)
      end

      travel_to(Time.zone.local(2026, 10, 31, 9, 6, 0)) do
        get company_dashboards_path(company, format: :json)
      end

      expect(Dashboards::OverviewService).to have_received(:call).twice
    end

    it "still deducts dashboard credits on a cache hit" do
      company.company_wallet.update_columns(promo_credit_balance: 0)
      company.company_wallet.add_credits!(amount: 100)

      get company_dashboards_path(company, format: :json)
      get company_dashboards_path(company, format: :json)

      expect(company.company_wallet.reload.main_credit_balance).to eq(96)
      expect(company.credit_usage_delta).to eq(4)
    end
  end
end
