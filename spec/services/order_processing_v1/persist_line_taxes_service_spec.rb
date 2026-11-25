# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderProcessingV1::PersistLineTaxesService do
  it "writes taxable and tax cents on the appointment" do
    company = create(:company)
    branch = create(:branch, company: company)
    customer = create(:customer, company: company)
    product = create(:product, company: company, branch: branch)
    order = create(:order, company: company, branch: branch, customer: customer)
    appointment = OrderProductAppointment.create!(
      company: company, order: order, product: product,
      quantity: 1, unit_price: 100.0, total_price: 100.0
    )

    line_tax = OrderProcessingV1::OrderTotalsService::LineTax.new(
      appointment_type: "OrderProductAppointment",
      appointment_id: appointment.id,
      taxable_cents: 9_000,
      tax_cents: 1_000
    )

    described_class.call(line_taxes: [ line_tax ])

    expect(appointment.reload.taxable_cents).to eq(9_000)
    expect(appointment.tax_cents).to eq(1_000)
  end
end
