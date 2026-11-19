# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::TaxConfigsController", type: :request do
  let(:company) { create(:company) }

  before { get sign_in_for_test_path(email: company.user.email) }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET /companies/:company_id/tax_config" do
    it "returns the POS tax fields with defaults" do
      get company_tax_config_path(company, format: :json)

      expect(response).to have_http_status(:ok)
      config = response.parsed_body["tax_config"]
      expect(config["pos_tax_rate_bp"]).to eq(0)
      expect(config["pos_tax_rate_percent"]).to eq(0.0)
      expect(config["pos_tax_name"]).to eq("Tax")
    end
  end

  describe "PATCH /companies/:company_id/tax_config" do
    it "converts the percent input to basis points" do
      patch company_tax_config_path(company, format: :json),
        params: { tax_config: { pos_tax_rate_percent: "8.25", pos_tax_name: "Sales tax" } }

      expect(response).to have_http_status(:ok), response.body
      config = TaxConfig.for_company!(company).reload
      expect(config.pos_tax_rate_bp).to eq(825)
      expect(config.pos_tax_name).to eq("Sales tax")
      expect(response.parsed_body.dig("tax_config", "pos_tax_rate_percent")).to eq(8.25)
    end

    it "rejects a rate above 100 without saving" do
      patch company_tax_config_path(company, format: :json),
        params: { tax_config: { pos_tax_rate_percent: "101" } }

      expect(response).to have_http_status(:unprocessable_content), response.body
      expect(response.parsed_body["errors"]).to be_present
      expect(TaxConfig.for_company!(company).reload.pos_tax_rate_bp).to eq(0)
    end

    it "rejects a non-numeric rate without saving" do
      patch company_tax_config_path(company, format: :json),
        params: { tax_config: { pos_tax_rate_percent: "not-a-rate" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(TaxConfig.for_company!(company).reload.pos_tax_rate_bp).to eq(0)
    end
  end
end
