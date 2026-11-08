# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::Analytics configuration", type: :request do
  let(:company) { create(:company, business_type: :retail, name: "Analytics Config Co") }
  let(:owner_user) { company.user }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  before { get sign_in_for_test_path(email: owner_user.email) }

  describe "GET /companies/:id/analytic" do
    it "returns the HTML shell" do
      get company_analytic_path(company)

      expect(response).to have_http_status(:ok)
    end

    it "returns the analytics configuration JSON" do
      analytic = company.analytic

      get company_analytic_path(company, format: :json)

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json.dig("analytic", "id")).to eq(analytic.id)
      expect(json.dig("analytic", "blocks")).to eq(Analytic::BLOCKS)
      expect(json.dig("analytic", "available_blocks")).to eq(Analytic::BLOCKS)
    end
  end

  describe "PATCH /companies/:id/analytic" do
    it "updates the active blocks" do
      patch company_analytic_path(company, format: :json),
        params: { analytic: { blocks: %w[pillars revenue_mix] } }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["message"]).to eq("Analytics updated successfully")
      expect(company.analytic.reload.blocks).to eq(%w[pillars revenue_mix])
    end

    it "allows hiding every block" do
      patch company_analytic_path(company, format: :json),
        params: { analytic: { blocks: [] } }

      expect(response).to have_http_status(:ok)
      expect(company.analytic.reload.blocks).to eq([])
    end

    it "clears every cached analytics period payload" do
      keys = CacheKeyService::ANALYTICS_PERIODS.map do |period|
        CacheKeyService.company_analytics(company.id, period)
      end
      keys.each { |key| Rails.sync_cache.write(key, { "stale" => true }) }

      patch company_analytic_path(company, format: :json),
        params: { analytic: { blocks: %w[pillars] } }

      keys.each { |key| expect(Rails.sync_cache.read(key)).to be_nil }
    end

    it "rejects unknown blocks with an errors array" do
      patch company_analytic_path(company, format: :json),
        params: { analytic: { blocks: %w[pillars not_a_real_block] } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to be_present
      expect(company.analytic.reload.blocks).to eq(Analytic::BLOCKS)
    end
  end

  describe "analytics index payload" do
    it "includes the active analytic blocks" do
      company.analytic.update!(blocks: %w[pillars revenue_mix])

      get company_analytics_path(company, format: :json)

      json = response.parsed_body
      expect(json.dig("analytic", "blocks")).to eq(%w[pillars revenue_mix])
    end
  end

  describe "authorization" do
    it "forbids a non-owner employee from updating" do
      employee_user = create(:user, :company_employee)
      create(:employee, company: company, user: employee_user, lifecycle_status: :active)
      get sign_in_for_test_path(email: employee_user.email)

      patch company_analytic_path(company, format: :json),
        params: { analytic: { blocks: %w[pillars] } }

      expect(response).to have_http_status(:forbidden)
      expect(company.analytic.reload.blocks).to eq(Analytic::BLOCKS)
    end
  end
end
