# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderProcessingV1::OrderTotalsService do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:product) { create(:product, company: company, branch: branch) }
  let(:customer) { create(:customer, company: company) }
  let(:order) do
    create(:order, company: company, branch: branch, customer: customer, currency: :usd).tap do |record|
      OrderProductAppointment.create!(
        company: company, order: record, product: product,
        quantity: 2, unit_price: 50.0, total_price: 100.0
      )
    end
  end

  def totals(discount_cents: 0)
    described_class.call(order: order, discount_cents: discount_cents)
  end

  it "adds the order's snapshotted tax to the subtotal" do
    order.update!(pos_tax_rate_bp: 800, pos_tax_name: "Sales tax")

    result = totals

    expect(result.subtotal_cents).to eq(10_000)
    expect(result.discount_cents).to eq(0)
    expect(result.tax_cents).to eq(800)
    expect(result.total_cents).to eq(10_800)
    expect(result.currency).to eq("usd")
    expect(result.tax_rate_bp).to eq(800)
    expect(result.tax_name).to eq("Sales tax")
  end

  it "calculates tax on the discounted subtotal" do
    order.update!(pos_tax_rate_bp: 800)

    result = totals(discount_cents: 1_000)

    expect(result.subtotal_cents).to eq(10_000)
    expect(result.discount_cents).to eq(1_000)
    expect(result.tax_cents).to eq(720)
    expect(result.total_cents).to eq(9_720)
  end

  it "returns zero tax when the rate is zero" do
    order.update!(pos_tax_rate_bp: 0)

    result = totals

    expect(result.tax_cents).to eq(0)
    expect(result.total_cents).to eq(10_000)
  end

  it "falls back to Tax Config when the order has no snapshot" do
    TaxConfig.for_company!(company).update!(pos_tax_rate_bp: 825, pos_tax_name: "VAT")

    result = totals

    expect(result.tax_rate_bp).to eq(825)
    expect(result.tax_name).to eq("VAT")
    expect(result.tax_cents).to eq(825)
    expect(result.total_cents).to eq(10_825)
  end

  it "keeps VND in whole dong" do
    order.update!(currency: :vnd, pos_tax_rate_bp: 800)
    order.order_product_appointments.first.update!(
      quantity: 1, unit_price: 50_000.0, total_price: 50_000.0
    )

    result = totals

    expect(result.currency).to eq("vnd")
    expect(result.subtotal_cents).to eq(50_000)
    expect(result.tax_cents).to eq(4_000)
    expect(result.total_cents).to eq(54_000)
  end
end
