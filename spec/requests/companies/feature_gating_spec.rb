# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Feature Gating API", type: :request do
  let(:company) { create(:company) }
  let(:owner_user) { company.user }

  before do
    get sign_in_for_test_path(email: owner_user.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  # ==========================================================================
  # JSON response body for disabled feature access
  # ==========================================================================

  describe "GET /companies/:id/employees.json when feature is disabled" do
    let!(:hrm_resource) do
      create(:billing_resource, :addon_feature, name: "hrm_attendance", country_code: company.country_code)
    end

    it "returns 403 Forbidden" do
      get "/companies/#{company.id}/employees", as: :json
      expect(response).to have_http_status(:forbidden)
    end

    it "includes feature_key in response body" do
      get "/companies/#{company.id}/employees", as: :json
      body = JSON.parse(response.body)
      expect(body["feature_key"]).to eq("hrm_attendance")
    end

    it "includes upgrade_url in response body" do
      get "/companies/#{company.id}/employees", as: :json
      body = JSON.parse(response.body)
      expect(body["upgrade_url"]).to eq("/companies/#{company.id}/billing")
    end

    it "includes error message in response body" do
      get "/companies/#{company.id}/employees", as: :json
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("Feature not available")
    end
  end

  describe "GET /companies/:id/employees.json when feature is enabled" do
    let!(:hrm_resource) do
      create(:billing_resource, :addon_feature, name: "hrm_attendance", country_code: company.country_code)
    end
    let(:contract) { company.active_billing_contract }

    before do
      create(:contract_feature, billing_contract: contract, billing_resource: hrm_resource, lifecycle_status: :active)
    end

    it "returns 200 OK" do
      get "/companies/#{company.id}/employees", as: :json
      expect(response).to have_http_status(:ok)
    end

    it "returns employee data in response" do
      get "/companies/#{company.id}/employees", as: :json
      body = JSON.parse(response.body)
      expect(body).to have_key("employees")
    end
  end

  # ==========================================================================
  # Toggle feature endpoint failure cases
  # ==========================================================================

  describe "POST /companies/:id/billing/toggle_feature" do
    let(:contract) { company.active_billing_contract }

    context "when toggling a core free feature" do
      it "returns 422 with error message" do
        post "/companies/#{company.id}/billing/toggle_feature", params: { feature_key: "pos_basic" }, as: :json
        expect(response).to have_http_status(:unprocessable_content)
        body = JSON.parse(response.body)
        expect(body["error"]).to eq("Core features cannot be toggled")
      end
    end

    context "when feature_key is missing" do
      it "returns 422 with error message" do
        post "/companies/#{company.id}/billing/toggle_feature", params: {}, as: :json
        expect(response).to have_http_status(:unprocessable_content)
        body = JSON.parse(response.body)
        expect(body["error"]).to eq("feature_key required")
      end
    end

    context "when feature_key does not exist in catalog" do
      it "returns 404" do
        post "/companies/#{company.id}/billing/toggle_feature", params: { feature_key: "nonexistent_feature" }, as: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when company has no active billing contract" do
      let(:company) { create(:company) }
      let(:owner_user) { company.user }

      before do
        contract = company.active_billing_contract
        contract&.update!(lifecycle_status: :expired)
      end

      it "returns 422 with error message" do
        create(:billing_resource, :addon_feature, name: "analytics_dashboard", country_code: company.country_code)
        post "/companies/#{company.id}/billing/toggle_feature", params: { feature_key: "analytics_dashboard" }, as: :json
        expect(response).to have_http_status(:unprocessable_content)
        body = JSON.parse(response.body)
        expect(body["error"]).to eq("No active billing contract")
      end
    end
  end

  # ==========================================================================
  # Ungated controller always works regardless of feature state
  # ==========================================================================

  describe "GET /companies/:id/categories.json" do
    it "returns 200 even when no features are enabled" do
      get "/companies/#{company.id}/categories", as: :json
      expect(response).to have_http_status(:ok)
    end
  end
end
