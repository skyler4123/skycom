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
      create(:billing_resource, :addon_feature, name: "hrm_attendance", country: company.country)
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
      create(:billing_resource, :addon_feature, name: "hrm_attendance", country: company.country)
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
        expect(body["errors"]).to contain_exactly("Core features cannot be toggled")
      end
    end

    context "when feature_key is missing" do
      it "returns 422 with error message" do
        post "/companies/#{company.id}/billing/toggle_feature", params: {}, as: :json
        expect(response).to have_http_status(:unprocessable_content)
        body = JSON.parse(response.body)
        expect(body["errors"]).to contain_exactly("feature_key required")
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
        create(:billing_resource, :addon_feature, name: "analytics_dashboard", country: company.country)
        post "/companies/#{company.id}/billing/toggle_feature", params: { feature_key: "analytics_dashboard" }, as: :json
        expect(response).to have_http_status(:unprocessable_content)
        body = JSON.parse(response.body)
        expect(body["errors"]).to contain_exactly("No active billing contract")
      end
    end
  end

  # ==========================================================================
  # Toggle feature endpoint success cases
  # ==========================================================================

  describe "POST /companies/:id/billing/toggle_feature" do
    let(:contract) { company.active_billing_contract }

    context "when toggling ON a disabled addon feature (first time)" do
      let!(:resource) do
        create(:billing_resource, :addon_feature, name: "analytics_dashboard", country: company.country)
      end

      it "returns 200 and active: true" do
        post "/companies/#{company.id}/billing/toggle_feature", params: { feature_key: "analytics_dashboard" }, as: :json
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["active"]).to be true
        expect(body["feature_key"]).to eq("analytics_dashboard")
      end

      it "creates a ContractFeature record in active state" do
        expect {
          post "/companies/#{company.id}/billing/toggle_feature", params: { feature_key: "analytics_dashboard" }, as: :json
        }.to change(ContractFeature, :count).by(1)
        expect(ContractFeature.last).to be_active
      end
    end

    context "when toggling OFF an active addon feature" do
      let!(:resource) do
        create(:billing_resource, :addon_feature, name: "analytics_dashboard", country: company.country)
      end
      let!(:contract_feature) do
        create(:contract_feature, billing_contract: contract, billing_resource: resource, lifecycle_status: :active)
      end

      it "returns 200 and active: false" do
        post "/companies/#{company.id}/billing/toggle_feature", params: { feature_key: "analytics_dashboard" }, as: :json
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["active"]).to be false
      end

      it "toggles the existing ContractFeature to disabled" do
        post "/companies/#{company.id}/billing/toggle_feature", params: { feature_key: "analytics_dashboard" }, as: :json
        expect(contract_feature.reload).to be_disabled
      end

      it "does not create a new ContractFeature" do
        expect {
          post "/companies/#{company.id}/billing/toggle_feature", params: { feature_key: "analytics_dashboard" }, as: :json
        }.not_to change(ContractFeature, :count)
      end
    end

    context "when toggling ON a disabled addon feature (previously disabled)" do
      let!(:resource) do
        create(:billing_resource, :addon_feature, name: "analytics_dashboard", country: company.country)
      end
      let!(:contract_feature) do
        create(:contract_feature, billing_contract: contract, billing_resource: resource, lifecycle_status: :disabled)
      end

      it "returns 200 and active: true" do
        post "/companies/#{company.id}/billing/toggle_feature", params: { feature_key: "analytics_dashboard" }, as: :json
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["active"]).to be true
      end

      it "toggles the existing ContractFeature back to active" do
        post "/companies/#{company.id}/billing/toggle_feature", params: { feature_key: "analytics_dashboard" }, as: :json
        expect(contract_feature.reload).to be_active
      end
    end

    context "when feature exists only for a different country" do
      let(:company) do
        create(:company).tap { |c| c.update!(country: :us) }
      end
      let(:owner_user) { company.reload.user }

      before do
        get sign_in_for_test_path(email: owner_user.email)
      end

      it "returns 404" do
        create(:billing_resource, :addon_feature, :vn, name: "analytics_dashboard")
        post "/companies/#{company.id}/billing/toggle_feature", params: { feature_key: "analytics_dashboard" }, as: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when feature exists for both countries but only enabled on correct one" do
      let(:company) do
        create(:company).tap { |c| c.update!(country: :us) }
      end
      let(:owner_user) { company.reload.user }
      let!(:us_resource) do
        create(:billing_resource, :addon_feature, name: "analytics_dashboard", country: :us)
      end
      let!(:vn_resource) do
        create(:billing_resource, :addon_feature, name: "analytics_dashboard", country: :vn)
      end
      let(:contract) { company.active_billing_contract }

      before do
        get sign_in_for_test_path(email: owner_user.email)
        create(:contract_feature, billing_contract: contract, billing_resource: us_resource, lifecycle_status: :active)
        Rails.local_cache.clear
      end

      it "returns 200 when feature is enabled on this country's resource" do
        get "/companies/#{company.id}/analytics", as: :json
        expect(response).to have_http_status(:ok)
      end
    end

    context "when toggling by an unauthorized user" do
      let!(:resource) do
        create(:billing_resource, :addon_feature, name: "analytics_dashboard", country: company.country)
      end
      let(:other_user) { create(:user) }

      before do
        get sign_in_for_test_path(email: other_user.email)
      end

      it "returns 403 Forbidden" do
        post "/companies/#{company.id}/billing/toggle_feature", params: { feature_key: "analytics_dashboard" }, as: :json
        expect(response).to have_http_status(:forbidden)
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
