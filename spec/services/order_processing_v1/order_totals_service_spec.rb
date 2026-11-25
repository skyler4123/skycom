# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderProcessingV1::OrderTotalsService do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:customer) { create(:customer, company: company) }
  let(:product_a) { create(:product, company: company, branch: branch) }
  let(:product_b) { create(:product, company: company, branch: branch) }
  let(:product_c) { create(:product, company: company, branch: branch) }
  let(:order) { create(:order, company: company, branch: branch, customer: customer, currency: :usd) }

  let!(:line_a) do
    OrderProductAppointment.create!(
      company: company, order: order, product: product_a,
      quantity: 2, unit_price: 50.0, total_price: 100.0
    )
  end
  let!(:line_b) do
    OrderProductAppointment.create!(
      company: company, order: order, product: product_b,
      quantity: 1, unit_price: 110.0, total_price: 110.0
    )
  end

  def totals(discount_cents: 0)
    described_class.call(order: order, discount_cents: discount_cents)
  end

  it "adds tax from an exclusive line" do
    line_b.destroy!
    line_a.update!(tax_name: "VAT", tax_rate_bp: 1_000, tax_inclusive: false)

    result = totals

    expect(result.subtotal_cents).to eq(10_000)
    expect(result.discount_cents).to eq(0)
    expect(result.tax_cents).to eq(1_000)
    expect(result.added_tax_cents).to eq(1_000)
    expect(result.total_cents).to eq(11_000)
    expect(result.currency).to eq("usd")
    expect(result.tax_lines).to contain_exactly(
      include(name: "VAT", rate_bp: 1_000, inclusive: false, taxable_cents: 10_000, tax_cents: 1_000)
    )
  end

  it "extracts tax from an inclusive line without changing the total" do
    line_b.destroy!
    line_a.update!(
      quantity: 2, unit_price: 55.0, total_price: 110.0,
      tax_name: "VAT", tax_rate_bp: 1_000, tax_inclusive: true
    )

    result = totals

    expect(result.subtotal_cents).to eq(11_000)
    expect(result.tax_cents).to eq(1_000)
    expect(result.added_tax_cents).to eq(0)
    expect(result.total_cents).to eq(11_000)
    expect(result.tax_lines).to contain_exactly(
      include(name: "VAT", rate_bp: 1_000, inclusive: true, taxable_cents: 10_000, tax_cents: 1_000)
    )
  end

  it "allocates a discount proportionally across mixed rates" do
    line_a.update!(tax_name: "VAT added", tax_rate_bp: 1_000, tax_inclusive: false)
    line_b.update!(tax_name: "VAT included", tax_rate_bp: 1_000, tax_inclusive: true)

    result = totals(discount_cents: 1_000)

    expect(result.subtotal_cents).to eq(21_000)
    expect(result.discount_cents).to eq(1_000)
    expect(result.tax_cents).to eq(result.line_taxes.sum(&:tax_cents))
    expect(result.total_cents).to eq(result.subtotal_cents - 1_000 + result.added_tax_cents)
    expect(result.tax_lines.map { |row| row[:name] }).to contain_exactly("VAT added", "VAT included")
  end

  it "distributes remaining discount cents exactly across three lines" do
    line_a.update!(quantity: 1, unit_price: 33.33, total_price: 33.33,
      tax_name: "VAT", tax_rate_bp: 1_000, tax_inclusive: false)
    line_b.update!(quantity: 1, unit_price: 33.33, total_price: 33.33,
      tax_name: "VAT", tax_rate_bp: 1_000, tax_inclusive: false)
    OrderProductAppointment.create!(
      company: company, order: order, product: product_c,
      quantity: 1, unit_price: 33.33, total_price: 33.33,
      tax_name: "VAT", tax_rate_bp: 1_000, tax_inclusive: false
    )

    result = totals(discount_cents: 1_000)

    expect(result.subtotal_cents).to eq(9_999)
    expect(result.line_taxes.sum(&:taxable_cents)).to eq(8_999)
    expect(result.line_taxes.sum(&:tax_cents)).to eq(900)
    expect(result.total_cents).to eq(9_899)
  end

  it "falls back to the company default when a line has no snapshot" do
    line_b.destroy!
    default = create(:tax_code, company: company, rate_bp: 825, name: "VAT")
    TaxConfig.for_company!(company).update!(default_tax_code_id: default.id)
    line_a.update!(tax_name: nil, tax_rate_bp: 0, tax_inclusive: false)

    result = totals

    expect(result.tax_cents).to eq(825)
    expect(result.total_cents).to eq(10_825)
  end

  it "returns zero tax when there is no code and no default" do
    line_b.destroy!
    line_a.update!(tax_name: nil)

    result = totals

    expect(result.tax_cents).to eq(0)
    expect(result.total_cents).to eq(10_000)
    expect(result.tax_lines).to be_empty
  end

  it "keeps VND in whole dong" do
    line_b.destroy!
    order.update!(currency: :vnd)
    line_a.update!(quantity: 1, unit_price: 50_000.0, total_price: 50_000.0,
      tax_name: "VAT", tax_rate_bp: 800, tax_inclusive: false)

    result = totals

    expect(result.currency).to eq("vnd")
    expect(result.subtotal_cents).to eq(50_000)
    expect(result.tax_cents).to eq(4_000)
    expect(result.total_cents).to eq(54_000)
  end
end
