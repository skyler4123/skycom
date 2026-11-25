# frozen_string_literal: true

require "rails_helper"

RSpec.describe TaxCodes::Resolver do
  it "prefers the record's kept tax code" do
    company = create(:company)
    assigned = create(:tax_code, company: company)
    default = create(:tax_code, company: company)
    TaxConfig.for_company!(company).update!(default_tax_code_id: default.id)
    product = create(:product, company: company, tax_code: assigned)

    expect(described_class.call(record: product)).to eq(assigned)
  end

  it "falls back to the company default" do
    company = create(:company)
    default = create(:tax_code, company: company)
    TaxConfig.for_company!(company).update!(default_tax_code_id: default.id)
    product = create(:product, company: company, tax_code: nil)

    expect(described_class.call(record: product)).to eq(default)
  end

  it "ignores a discarded assigned code and a discarded default" do
    company = create(:company)
    assigned = create(:tax_code, company: company)
    default = create(:tax_code, company: company)
    TaxConfig.for_company!(company).update!(default_tax_code_id: default.id)
    product = create(:product, company: company, tax_code: assigned)
    assigned.discard!
    default.discard!

    expect(described_class.call(record: product)).to be_nil
  end
end
