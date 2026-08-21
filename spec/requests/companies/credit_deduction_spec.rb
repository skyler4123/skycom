# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Credit deduction via after_action", type: :request do
  let(:company) { create(:company, country: :us, currency: :usd) }
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

  describe "GET /companies/:company_id/dashboards" do
    it "deducts dashboard credits after a successful JSON request" do
      company.company_wallet.add_to!(balance: :main, amount: 100)

      get "/companies/#{company.id}/dashboards.json"

      expect(response).to have_http_status(:ok)
      expect(company.company_wallet.reload.main_credit_balance).to eq(98)
      expect(company.credit_usage_delta).to eq(2)
    end

    it "deducts from the promo balance before the main balance" do
      company.company_wallet.add_to!(balance: :promo, amount: 5)
      company.company_wallet.add_to!(balance: :main, amount: 100)

      get "/companies/#{company.id}/dashboards.json"

      expect(company.company_wallet.reload.promo_credit_balance).to eq(3)
      expect(company.company_wallet.reload.main_credit_balance).to eq(100)
    end

    it "absorbs the shortfall into debt and still renders" do
      company.company_wallet.add_to!(balance: :main, amount: 1)

      get "/companies/#{company.id}/dashboards.json"

      expect(response).to have_http_status(:ok)
      expect(company.company_wallet.reload.main_credit_balance).to eq(0)
      expect(company.company_wallet.reload.debt_credit_balance).to eq(1)
    end

    it "does not deduct on HTML requests" do
      company.company_wallet.add_to!(balance: :main, amount: 100)

      get "/companies/#{company.id}/dashboards"

      expect(company.company_wallet.reload.main_credit_balance).to eq(100)
    end

    it "never breaks the response when the deduction raises" do
      allow(CompanyCreditDeduction::Companies::Dashboards::IndexService).to receive(:call).and_raise(RuntimeError, "boom")
      company.company_wallet.add_to!(balance: :main, amount: 100)

      get "/companies/#{company.id}/dashboards.json"

      expect(response).to have_http_status(:ok)
    end

    it "exposes the wallet balances in the JSON payload" do
      company.company_wallet.add_to!(balance: :promo, amount: 3)
      company.company_wallet.add_to!(balance: :main, amount: 50)

      get "/companies/#{company.id}/dashboards.json"

      body = JSON.parse(response.body)
      expect(body["wallet"]).to include(
        "main_credit_balance" => 50,
        "promo_credit_balance" => 3,
        "debt_credit_balance" => 0
      )
    end

    it "does not include a credit_warning key in the payload" do
      company.company_wallet.add_to!(balance: :main, amount: 1)

      get "/companies/#{company.id}/dashboards.json"

      expect(JSON.parse(response.body)).not_to have_key("credit_warning")
    end
  end
end
