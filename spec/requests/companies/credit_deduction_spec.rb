# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Credit deduction via page tokens", type: :request do
  let(:company) { create(:company, :without_signup_promo, country: :us, currency: :usd) }
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

  def page_token(path = "/companies/#{company.id}/dashboards")
    get path
    expect(response).to have_http_status(:ok)

    Nokogiri::HTML(response.body).at_css("body")["data-credit-page-token"]
  end

  def get_json(path = "/companies/#{company.id}/dashboards.json", token: nil)
    headers = token ? { "X-Credit-Page-Token" => token } : {}
    get path, headers: headers
  end

  describe "dashboard index" do
    it "does not charge the HTML shell and returns a page token" do
      wallet.add_to!(balance: :main, amount: 100)

      token = page_token

      expect(token).to be_present
      expect(wallet.reload.main_credit_balance).to eq(100)
      expect(company.credit_usage_delta).to eq(0)
    end

    it "does not charge a JSON request without a token" do
      wallet.add_to!(balance: :main, amount: 100)

      get_json

      expect(response).to have_http_status(:ok)
      expect(wallet.reload.main_credit_balance).to eq(100)
      expect(company.credit_usage_delta).to eq(0)
    end

    it "charges once for the first JSON request with a page token" do
      wallet.add_to!(balance: :main, amount: 100)
      token = page_token

      get_json(token: token)

      expect(response).to have_http_status(:ok)
      expect(wallet.reload.main_credit_balance).to eq(98)
      expect(company.credit_usage_delta).to eq(2)
    end

    it "does not charge later JSON requests with the same token" do
      wallet.add_to!(balance: :main, amount: 100)
      token = page_token

      get_json(token: token)
      get_json(token: token)

      expect(wallet.reload.main_credit_balance).to eq(98)
      expect(company.credit_usage_delta).to eq(2)
    end

    it "charges again when a new page load mints a new token" do
      wallet.add_to!(balance: :main, amount: 100)

      get_json(token: page_token)
      get_json(token: page_token)

      expect(wallet.reload.main_credit_balance).to eq(96)
      expect(company.credit_usage_delta).to eq(4)
    end

    it "does not charge an invalid token" do
      wallet.add_to!(balance: :main, amount: 100)

      get_json(token: "tampered")

      expect(response).to have_http_status(:ok)
      expect(wallet.reload.main_credit_balance).to eq(100)
      expect(company.credit_usage_delta).to eq(0)
    end

    it "deducts from the promo balance before the main balance" do
      wallet.add_to!(balance: :promo, amount: 5)
      wallet.add_to!(balance: :main, amount: 100)

      get_json(token: page_token)

      expect(wallet.reload.promo_credit_balance).to eq(3)
      expect(wallet.main_credit_balance).to eq(100)
    end

    it "allows the balance to go negative and still renders" do
      wallet.add_to!(balance: :main, amount: 1)

      get_json(token: page_token)

      expect(response).to have_http_status(:ok)
      expect(wallet.reload.main_credit_balance).to eq(-1)
      expect(company.reload.workflow_status).to eq("suspend")
    end

    it "never breaks the response when the deduction raises and releases the claim" do
      wallet.add_to!(balance: :main, amount: 100)
      token = page_token
      allow(CompanyCreditDeduction::DeductionService).to receive(:call).and_raise(RuntimeError, "boom")

      get_json(token: token)

      expect(response).to have_http_status(:ok)
      expect(wallet.reload.main_credit_balance).to eq(100)
      expect(company.claim_credit_page_token!(token)).to be(true)
    end

    it "exposes the wallet balances in the JSON payload" do
      wallet.add_to!(balance: :promo, amount: 3)
      wallet.add_to!(balance: :main, amount: 50)

      get_json

      body = JSON.parse(response.body)
      expect(body["wallet"]).to include(
        "main_credit_balance" => 50,
        "promo_credit_balance" => 3
      )
      expect(body["wallet"]).not_to have_key("debt_credit_balance")
    end

    it "does not include a credit_warning key in the payload" do
      wallet.add_to!(balance: :main, amount: 1)

      get_json

      expect(JSON.parse(response.body)).not_to have_key("credit_warning")
    end
  end

  describe "future charge triggers" do
    it "charges the HTML page when a rule uses charge_on: :html" do
      wallet.add_to!(balance: :main, amount: 100)
      stub_const("CREDIT_DEDUCTION_RATES", {
        "companies/dashboards#index" => {
          cost: 2, action_type: "access_dashboard",
          description: "Dashboard access", charge_on: :html
        }.freeze
      }.freeze)

      get "/companies/#{company.id}/dashboards"

      expect(response).to have_http_status(:ok)
      expect(wallet.reload.main_credit_balance).to eq(98)
      expect(Nokogiri::HTML(response.body).at_css("body")["data-credit-page-token"]).to be_blank
    end

    it "charges every JSON request when a rule uses charge_on: :every_request" do
      wallet.add_to!(balance: :main, amount: 100)
      stub_const("CREDIT_DEDUCTION_RATES", {
        "companies/dashboards#index" => {
          cost: 2, action_type: "access_dashboard",
          description: "Dashboard access", charge_on: :every_request
        }.freeze
      }.freeze)

      2.times { get_json }

      expect(wallet.reload.main_credit_balance).to eq(96)
      expect(company.credit_usage_delta).to eq(4)
    end
  end
end
