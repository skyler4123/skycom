# frozen_string_literal: true

require "rails_helper"

RSpec.describe TaxCodes::DiscardService do
  it "discards the code, clears assignments, and clears the default" do
    company = create(:company)
    code = create(:tax_code, company: company)
    product = create(:product, company: company, tax_code: code)
    category = Seed::CategoryService.find_or_create_for(company: company, resource_name: "services")
    service = Service.create!(
      company: company,
      name: "Discard validation service",
      business_type: :b2c,
      category: category,
      property_mapping: category.default_property_mapping,
      tax_code: code
    )
    TaxConfig.for_company!(company).update!(default_tax_code_id: code.id)

    described_class.call(tax_code: code)

    expect(code.reload).to be_discarded
    expect(product.reload.tax_code_id).to be_nil
    expect(service.reload.tax_code_id).to be_nil
    expect(TaxConfig.for_company!(company).reload.default_tax_code_id).to be_nil
  end
end
