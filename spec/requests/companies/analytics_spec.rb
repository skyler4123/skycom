# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::Analytics", type: :request do
  let(:company) { create(:company) }
  let(:owner_user) { company.user }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET /companies/:id/analytics" do
    context "when authenticated" do
      before do
        get sign_in_for_test_path(email: owner_user.email)
      end

      it "returns HTML shell" do
        get company_analytics_path(company)
        expect(response).to have_http_status(:ok)
      end

      it "returns JSON with analytics data" do
        get company_analytics_path(company, format: :json)
        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json).to have_key("summary")
        expect(json).to have_key("profit_margins")
        expect(json).to have_key("inventory_velocity")
        expect(json).to have_key("staff_performance")
        expect(json).to have_key("customer_clv")
      end

      it "accepts period param" do
        get company_analytics_path(company, format: :json, params: { period: "last_month" })
        expect(response).to have_http_status(:ok)
      end
    end

    context "without authentication" do
      it "redirects to root path" do
        get company_analytics_path(company, format: :json)
        expect(response).to have_http_status(:found)
      end
    end
  end
end
