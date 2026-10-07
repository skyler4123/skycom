# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::NotificationConfigsController", type: :request do
  let(:company) { create(:company) }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  before { get sign_in_for_test_path(email: company.user.email) }

  describe "GET #show" do
    it "returns the employee's config" do
      get company_notification_config_path(company), as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to have_key("notification_config")
    end
  end

  describe "PATCH #update" do
    it "updates preferences but never last_read_all_at" do
      patch company_notification_config_path(company),
        params: { notification_config: { preferences: { mobile: true }, last_read_all_at: 1.day.ago } },
        as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)["notification_config"]
      expect(body["preferences"]).to include("mobile" => true)
    end
  end
end
