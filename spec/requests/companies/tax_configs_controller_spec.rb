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
    it "returns the default tax code as nil when unset" do
      get company_tax_config_path(company, format: :json)

      expect(response).to have_http_status(:ok)
      config = response.parsed_body["tax_config"]
      expect(config["default_tax_code_id"]).to be_nil
      expect(config["default_tax_code"]).to be_nil
    end

    it "returns the selected default tax code" do
      code = create(:tax_code, company: company, name: "VAT 10%", rate_bp: 1_000)
      TaxConfig.for_company!(company).update!(default_tax_code_id: code.id)

      get company_tax_config_path(company, format: :json)

      config = response.parsed_body["tax_config"]
      expect(config["default_tax_code_id"]).to eq(code.id)
      expect(config.dig("default_tax_code", "name")).to eq("VAT 10%")
    end
  end

  describe "PATCH /companies/:company_id/tax_config" do
    it "saves the default tax code" do
      code = create(:tax_code, company: company)

      patch company_tax_config_path(company, format: :json),
        params: { tax_config: { default_tax_code_id: code.id } }

      expect(response).to have_http_status(:ok), response.body
      expect(TaxConfig.for_company!(company).reload.default_tax_code_id).to eq(code.id)
      expect(response.parsed_body.dig("tax_config", "default_tax_code", "id")).to eq(code.id)
    end

    it "rejects another company's tax code without saving" do
      other = create(:tax_code)

      patch company_tax_config_path(company, format: :json),
        params: { tax_config: { default_tax_code_id: other.id } }

      expect(response).to have_http_status(:unprocessable_content), response.body
      expect(response.parsed_body["errors"]).to be_present
      expect(TaxConfig.for_company!(company).reload.default_tax_code_id).to be_nil
    end

    it "clears the default" do
      code = create(:tax_code, company: company)
      TaxConfig.for_company!(company).update!(default_tax_code_id: code.id)

      patch company_tax_config_path(company, format: :json),
        params: { tax_config: { default_tax_code_id: "" } }

      expect(response).to have_http_status(:ok), response.body
      expect(TaxConfig.for_company!(company).reload.default_tax_code_id).to be_nil
    end
  end
end
