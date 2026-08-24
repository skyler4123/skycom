# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::UsageController usage logging", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:company) { create(:company, country: :us, currency: :usd) }
  let(:owner_user) { company.user }
  let(:wallet) { company.company_wallet }

  before do
    get sign_in_for_test_path(email: owner_user.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET /companies/:company_id/usage.json" do
    it "reports usage logging as inactive with no logs by default" do
      get "/companies/#{company.id}/usage.json"

      body = JSON.parse(response.body)
      expect(body["usage_logging"]).to include(
        "active" => false,
        "until" => nil,
        "seconds_remaining" => 0
      )
      expect(body["usage_logs"]).to eq([])
    end

    it "returns window logs only while logging is active" do
      wallet.enable_usage_logging!
      wallet.add_to!(balance: :main, amount: 40, description: "seed", action_type: "top_up")
      wallet.disable_usage_logging!

      get "/companies/#{company.id}/usage.json"
      expect(JSON.parse(response.body)["usage_logs"]).to eq([])

      wallet.enable_usage_logging!
      wallet.add_to!(balance: :promo, amount: 7, description: "grant", action_type: "top_up")

      get "/companies/#{company.id}/usage.json"

      body = JSON.parse(response.body)
      expect(body["usage_logging"]["active"]).to be true
      logs = body["usage_logs"]
      expect(logs.size).to eq(1)
      expect(logs.first).to include(
        "action_type" => "top_up",
        "change_amount" => 7,
        "description" => "grant"
      )
      expect(logs.first["balance_after"]).to eq(wallet.reload.total_credit_balance)
    end
  end

  describe "POST /companies/:company_id/usage/enable_logging" do
    it "activates the logging window" do
      post "/companies/#{company.id}/usage/enable_logging"

      expect(response).to have_http_status(:ok)
      expect(wallet.reload.usage_logging_active?).to be true

      body = JSON.parse(response.body)
      expect(body["message"]).to be_present
      expect(body["usage_logging"]["active"]).to be true
    end

    it "extends the window when already active" do
      travel_to(Time.zone.local(2026, 8, 24, 10, 0, 0)) do
        wallet.enable_usage_logging!
        first_until = wallet.reload.usage_logging_until

        travel(1.minute)
        post "/companies/#{company.id}/usage/enable_logging"

        expect(wallet.reload.usage_logging_until).to be > first_until
      end
    end

    it "returns unprocessable content when the wallet is missing" do
      wallet.destroy!

      post "/companies/#{company.id}/usage/enable_logging"

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end

    it "returns forbidden when the employee cannot update the wallet" do
      allow_any_instance_of(Employee).to receive(:can?).with(:update, CompanyWallet).and_return(false)

      post "/companies/#{company.id}/usage/enable_logging.json"

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end
  end

  describe "POST /companies/:company_id/usage/disable_logging" do
    it "clears the logging window" do
      wallet.enable_usage_logging!

      post "/companies/#{company.id}/usage/disable_logging"

      expect(response).to have_http_status(:ok)
      expect(wallet.reload.usage_logging_active?).to be false
      expect(JSON.parse(response.body)["usage_logging"]["active"]).to be false
    end
  end
end
