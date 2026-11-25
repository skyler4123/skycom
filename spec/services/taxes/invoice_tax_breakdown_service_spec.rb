# frozen_string_literal: true

require "rails_helper"

RSpec.describe Taxes::InvoiceTaxBreakdownService do
  it "groups tax by name, rate, and treatment" do
    company = create(:company)
    customer = create(:customer, company: company)
    category = Seed::CategoryService.find_or_create_for(company: company, resource_name: "invoices")
    order_a = create(:order, company: company, customer: customer)
    order_b = create(:order, company: company, customer: customer)

    invoice_a = create(:invoice, company: company, category: category, order: order_a,
      metadata: { "tax_breakdown" => [
        { "name" => "VAT", "rate_bp" => 1_000, "inclusive" => false, "taxable_cents" => 10_000, "tax_cents" => 1_000 }
      ] })
    invoice_b = create(:invoice, company: company, category: category, order: order_b,
      metadata: { "tax_breakdown" => [
        { "name" => "VAT", "rate_bp" => 1_000, "inclusive" => false, "taxable_cents" => 5_000, "tax_cents" => 500 },
        { "name" => "VAT", "rate_bp" => 1_000, "inclusive" => true, "taxable_cents" => 4_500, "tax_cents" => 500 }
      ] })

    rows = described_class.call(invoices: Invoice.where(id: [ invoice_a.id, invoice_b.id ]))

    expect(rows).to contain_exactly(
      include(name: "VAT", rate_bp: 1_000, inclusive: false, taxable_cents: 15_000, tax_cents: 1_500),
      include(name: "VAT", rate_bp: 1_000, inclusive: true, taxable_cents: 4_500, tax_cents: 500)
    )
  end

  it "ignores invoices without a breakdown" do
    company = create(:company)
    customer = create(:customer, company: company)
    category = Seed::CategoryService.find_or_create_for(company: company, resource_name: "invoices")
    order = create(:order, company: company, customer: customer)
    invoice = create(:invoice, company: company, category: category, order: order, metadata: {})

    expect(described_class.call(invoices: Invoice.where(id: invoice.id))).to eq([])
  end
end
