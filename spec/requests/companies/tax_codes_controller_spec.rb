# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::TaxCodesController", type: :request do
  let(:company) { create(:company) }

  before { get sign_in_for_test_path(email: company.user.email) }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET /companies/:company_id/tax_codes" do
    it "returns kept codes with usage counts" do
      code = create(:tax_code, company: company, name: "VAT 10%")
      product = create(:product, company: company, tax_code: code)
      create(:product, company: company, tax_code: nil)

      get company_tax_codes_path(company, format: :json)

      expect(response).to have_http_status(:ok)
      row = response.parsed_body["tax_codes"].find { |candidate| candidate["id"] == code.id }
      expect(row).to include("name" => "VAT 10%", "rate_percent" => 10.0, "products_count" => 1)
      expect(row["id"]).to eq(code.id)
      expect(product.reload.tax_code).to eq(code)
    end

    it "does not return discarded codes" do
      code = create(:tax_code, company: company)
      code.discard!

      get company_tax_codes_path(company, format: :json)

      expect(response.parsed_body["tax_codes"]).to be_empty
    end
  end

  describe "POST /companies/:company_id/tax_codes" do
    it "creates a tax code from percent input" do
      post company_tax_codes_path(company, format: :json),
        params: {
          tax_code: {
            name: "VAT 10%",
            code: "VAT10",
            kind: "vat",
            rate_percent: "10",
            is_inclusive: "true"
          }
        }

      expect(response).to have_http_status(:created), response.body
      code = company.tax_codes.last
      expect(code.rate_bp).to eq(1_000)
      expect(code.is_inclusive).to be(true)
      expect(response.parsed_body.dig("tax_code", "rate_percent")).to eq(10.0)
      expect(response.parsed_body["message"]).to eq("Tax code created")
    end

    it "rejects an invalid rate without saving" do
      post company_tax_codes_path(company, format: :json),
        params: { tax_code: { name: "Bad", rate_percent: "101" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to be_present
      expect(company.tax_codes.count).to eq(0)
    end

    it "rejects a duplicate code in the same company" do
      create(:tax_code, company: company, code: "VAT10")

      post company_tax_codes_path(company, format: :json),
        params: { tax_code: { name: "Another VAT", code: "VAT10", rate_percent: "10" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to be_present
    end
  end

  describe "PATCH/DELETE /companies/:company_id/tax_codes/:id" do
    it "updates the rate and discards the code" do
      code = create(:tax_code, company: company, rate_bp: 1_000)

      patch company_tax_code_path(company, code, format: :json),
        params: { tax_code: { rate_percent: "8.25" } }

      expect(response).to have_http_status(:ok), response.body
      expect(code.reload.rate_bp).to eq(825)

      delete company_tax_code_path(company, code, format: :json)

      expect(response).to have_http_status(:ok)
      expect(code.reload).to be_discarded
    end
  end
end
