# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::Dashboard configuration", type: :request do
  let(:company) { create(:company, business_type: :retail, name: "Dashboard Config Co") }
  let(:owner_user) { company.user }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  before { get sign_in_for_test_path(email: owner_user.email) }

  describe "GET /companies/:id/dashboard" do
    it "returns the HTML shell" do
      get company_dashboard_path(company)

      expect(response).to have_http_status(:ok)
    end

    it "returns the dashboard configuration JSON" do
      dashboard = company.dashboard

      get company_dashboard_path(company, format: :json)

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json.dig("dashboard", "id")).to eq(dashboard.id)
      expect(json.dig("dashboard", "blocks")).to eq(Dashboard::BLOCKS)
      expect(json.dig("dashboard", "available_blocks")).to eq(Dashboard::BLOCKS)
    end
  end

  describe "PATCH /companies/:id/dashboard" do
    it "updates the active blocks" do
      patch company_dashboard_path(company, format: :json),
        params: { dashboard: { blocks: %w[kpis company_wallet] } }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["message"]).to eq("Dashboard updated successfully")
      expect(company.dashboard.reload.blocks).to eq(%w[kpis company_wallet])
    end

    it "allows hiding every block" do
      patch company_dashboard_path(company, format: :json),
        params: { dashboard: { blocks: [] } }

      expect(response).to have_http_status(:ok)
      expect(company.dashboard.reload.blocks).to eq([])
    end

    it "clears both cached dashboard payloads" do
      financial_key = CacheKeyService.company_dashboard(company.id, can_view_financials: true)
      operational_key = CacheKeyService.company_dashboard(company.id, can_view_financials: false)
      Rails.sync_cache.write(financial_key, { "stale" => true })
      Rails.sync_cache.write(operational_key, { "stale" => true })

      patch company_dashboard_path(company, format: :json),
        params: { dashboard: { blocks: %w[kpis] } }

      expect(Rails.sync_cache.read(financial_key)).to be_nil
      expect(Rails.sync_cache.read(operational_key)).to be_nil
    end

    it "rejects unknown blocks with an errors array" do
      patch company_dashboard_path(company, format: :json),
        params: { dashboard: { blocks: %w[kpis not_a_real_block] } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to be_present
      expect(company.dashboard.reload.blocks).to eq(Dashboard::BLOCKS)
    end
  end

  describe "dashboard index payload" do
    it "includes the active dashboard blocks" do
      company.dashboard.update!(blocks: %w[kpis recent_orders])

      get company_dashboards_path(company, format: :json)

      json = response.parsed_body
      expect(json.dig("dashboard", "blocks")).to eq(%w[kpis recent_orders])
    end
  end

  describe "authorization" do
    it "forbids a non-owner employee from updating" do
      employee_user = create(:user, :company_employee)
      create(:employee, company: company, user: employee_user, lifecycle_status: :active)
      get sign_in_for_test_path(email: employee_user.email)

      patch company_dashboard_path(company, format: :json),
        params: { dashboard: { blocks: %w[kpis] } }

      expect(response).to have_http_status(:forbidden)
      expect(company.dashboard.reload.blocks).to eq(Dashboard::BLOCKS)
    end
  end
end
