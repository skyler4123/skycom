# frozen_string_literal: true

require "rails_helper"

RSpec.describe Seed::ServiceService do
  def company_for(currency:, country:)
    Seed::CompanyService.create(
      user: create(:user, :company_owner),
      business_type: :retail,
      country: country,
      currency: currency
    )
  end

  it "sets price cents in the company currency" do
    company = company_for(currency: :usd, country: :us)

    service = described_class.create(company: company, price: 100)

    expect(service.price_cents).to eq(10_000)
    expect(service.currency).to eq("usd")
  end

  it "keeps VND in whole dong" do
    company = company_for(currency: :vnd, country: :vn)

    service = described_class.create(company: company, price: 500_000)

    expect(service.price_cents).to eq(500_000)
    expect(service.currency).to eq("vnd")
  end

  describe ".demo_price" do
    it "returns whole VND amounts and whole-unit USD amounts" do
      vnd = company_for(currency: :vnd, country: :vn)
      usd = company_for(currency: :usd, country: :us)

      expect(described_class.demo_price(vnd)).to be_between(500_000, 3_000_000)
      expect(described_class.demo_price(usd)).to be_between(50, 300)
    end
  end
end
