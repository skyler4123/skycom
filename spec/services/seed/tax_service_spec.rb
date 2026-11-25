# frozen_string_literal: true

require "rails_helper"

RSpec.describe Seed::TaxService do
  def company_for(business_type:, country:, currency:)
    Seed::CompanyService.create(
      user: create(:user, :company_owner),
      business_type: business_type,
      country: country,
      currency: currency
    )
  end

  describe ".ensure_neutral_code!" do
    it "creates a zero-rate code with the country kind and no default" do
      us = company_for(business_type: :retail, country: :us, currency: :usd)
      vn = company_for(business_type: :retail, country: :vn, currency: :vnd)

      us_code = described_class.ensure_neutral_code!(company: us)
      vn_code = described_class.ensure_neutral_code!(company: vn)

      expect(us_code).to have_attributes(code: "NO_TAX", kind: "sales", rate_bp: 0)
      expect(vn_code).to have_attributes(code: "NO_TAX", kind: "vat", rate_bp: 0)
      expect(TaxConfig.for_company!(us).default_tax_code_id).to be_nil
      expect(TaxConfig.for_company!(vn).default_tax_code_id).to be_nil
    end

    it "is idempotent" do
      company = company_for(business_type: :retail, country: :us, currency: :usd)

      described_class.ensure_neutral_code!(company: company)
      described_class.ensure_neutral_code!(company: company)

      expect(company.tax_codes.where(code: "NO_TAX").count).to eq(1)
    end
  end

  describe ".enrich!" do
    profile_expectations = {
      [ :retail, :us ] => {
        currency: :usd,
        product: [ "SALES_825", 825, false ],
        service: [ "SALES_0_SERVICE", 0, false ]
      },
      [ :retail, :vn ] => {
        currency: :vnd,
        product: [ "VAT_10", 1_000, true ],
        service: [ "VAT_8", 800, true ]
      },
      [ :hospital, :vn ] => {
        currency: :vnd,
        product: [ "VAT_5_PHARMACY", 500, true ],
        service: [ "VAT_0_MEDICAL", 0, true ]
      },
      [ :hotel, :vn ] => {
        currency: :vnd,
        product: [ "VAT_10_MINIBAR", 1_000, true ],
        service: [ "VAT_5_ACCOMMODATION", 500, true ]
      }
    }

    profile_expectations.each do |(business_type, country), expected|
      it "seeds the #{business_type}/#{country} profile and assigns its items" do
        company = company_for(business_type: business_type, country: country, currency: expected[:currency])
        product = create(:product, company: company)
        service = Seed::ServiceService.create(company: company)

        result = described_class.enrich!(company: company)

        product_code = company.tax_codes.find_by!(code: expected[:product][0])
        service_code = company.tax_codes.find_by!(code: expected[:service][0])

        expect(product_code).to have_attributes(
          rate_bp: expected[:product][1],
          is_inclusive: expected[:product][2]
        )
        expect(service_code).to have_attributes(
          rate_bp: expected[:service][1],
          is_inclusive: expected[:service][2]
        )
        expect(product.reload.tax_code).to eq(product_code)
        expect(service.reload.tax_code).to eq(service_code)
        expect(TaxConfig.for_company!(company).default_tax_code).to eq(product_code)
        expect(result[:profile]).to eq([ business_type.to_s, country.to_s ])
      end
    end

    it "does not overwrite existing code attributes, assignments, or the default" do
      company = company_for(business_type: :retail, country: :us, currency: :usd)
      existing_product_code = company.tax_codes.create!(
        code: "SALES_825", name: "Custom sales", rate_bp: 500, kind: :sales
      )
      custom_code = company.tax_codes.create!(
        code: "CUSTOM", name: "Custom", rate_bp: 100, kind: :sales
      )
      product = create(:product, company: company, tax_code: custom_code)
      service = Seed::ServiceService.create(company: company)
      TaxConfig.for_company!(company).update!(default_tax_code_id: custom_code.id)

      described_class.enrich!(company: company)

      expect(existing_product_code.reload).to have_attributes(name: "Custom sales", rate_bp: 500)
      expect(product.reload.tax_code).to eq(custom_code)
      expect(service.reload.tax_code.code).to eq("SALES_0_SERVICE")
      expect(TaxConfig.for_company!(company).default_tax_code).to eq(custom_code)
    end

    it "is idempotent" do
      company = company_for(business_type: :retail, country: :us, currency: :usd)
      create(:product, company: company)
      Seed::ServiceService.create(company: company)

      first = described_class.enrich!(company: company)
      code_count = company.tax_codes.count
      second = described_class.enrich!(company: company)

      expect(first[:products_updated]).to eq(1)
      expect(first[:services_updated]).to eq(1)
      expect(second[:products_updated]).to eq(0)
      expect(second[:services_updated]).to eq(0)
      expect(second[:default_set]).to be(false)
      expect(company.tax_codes.count).to eq(code_count)
    end

    it "creates only the neutral code when no profile matches" do
      company = company_for(business_type: :education, country: :us, currency: :usd)

      result = described_class.enrich!(company: company)

      expect(result[:profile]).to be_nil
      expect(company.tax_codes.pluck(:code)).to contain_exactly("NO_TAX")
      expect(TaxConfig.for_company!(company).default_tax_code_id).to be_nil
    end

    it "skips system companies" do
      company = company_for(business_type: :retail, country: :us, currency: :usd)
      allow(company).to receive(:system_company?).and_return(true)

      expect(described_class.enrich!(company: company)).to be_nil
      expect(company.tax_codes.count).to eq(0)
    end
  end

  describe ".enrich_all!" do
    it "enriches every non-system company" do
      us = company_for(business_type: :retail, country: :us, currency: :usd)
      vn = company_for(business_type: :hotel, country: :vn, currency: :vnd)

      results = described_class.enrich_all!

      expect(us.tax_codes.find_by(code: "SALES_825")).to be_present
      expect(vn.tax_codes.find_by(code: "VAT_10_MINIBAR")).to be_present
      expect(results.size).to be >= 2
    end
  end
end
