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
        expect(json).to have_key("period")
        expect(json).to have_key("summary")
        expect(json).to have_key("profit_margins")
        expect(json).to have_key("revenue_mix")
        expect(json["revenue_mix"]).to have_key("by_category")
        expect(json["revenue_mix"]).to have_key("by_branch")
        expect(json).to have_key("top_items")
        expect(json["top_items"]).to have_key("products")
        expect(json["top_items"]).to have_key("services")
        expect(json).to have_key("inventory_velocity")
        expect(json).to have_key("staff_performance")
        expect(json["staff_performance"]).to have_key("totals")
        expect(json).to have_key("customer_clv")
        expect(json["customer_clv"]).to have_key("repeat_customer_rate")
        expect(json).to have_key("cohorts")
      end

      it "accepts period param" do
        get company_analytics_path(company, format: :json, params: { period: "last_month" })
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.dig("period", "key")).to eq("last_month")
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

      it "denies the JSON payload" do
        get company_analytics_path(company, format: :json)

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["errors"]).to be_present
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
