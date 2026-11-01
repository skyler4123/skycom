require "rails_helper"

RSpec.describe Kpi::Metrics::OrdersRevenueCents do
  let(:company) { create(:company) }
  let(:employee) { create(:employee, company: company) }
  let(:coworker) { create(:employee, company: company) }
  let(:range_from) { Time.zone.parse("2026-03-01 00:00:00") }
  let(:range_to) { Time.zone.parse("2026-03-31 23:59:59") }
  let(:in_range) { Time.zone.parse("2026-03-15 10:00:00") }

  it "sums paid order revenue per salesperson in cents" do
    create_paid_order(company: company, salesperson: employee, created_at: in_range, total_price: 50.0)
    create_paid_order(company: company, salesperson: employee, created_at: in_range, total_price: 25.0)
    create_paid_order(company: company, salesperson: coworker, created_at: in_range, total_price: 80.0)

    result = described_class.call(
      company: company,
      employee_ids: [ employee.id, coworker.id ],
      from: range_from,
      to: range_to
    )

    expect(result[employee.id]).to eq(7500)
    expect(result[coworker.id]).to eq(8000)
  end

  it "returns zero for an employee with no revenue" do
    result = described_class.call(
      company: company,
      employee_ids: [ employee.id ],
      from: range_from,
      to: range_to
    )

    expect(result[employee.id]).to eq(0)
  end

  it "excludes unpaid, discarded, and out-of-range orders" do
    create_paid_order(company: company, salesperson: employee, created_at: in_range, total_price: 50.0, workflow_status: :pending)
    create_paid_order(company: company, salesperson: employee, created_at: in_range, total_price: 50.0)
      .update_columns(discarded_at: Time.current)
    create_paid_order(company: company, salesperson: employee, created_at: in_range - 1.month, total_price: 50.0)

    result = described_class.call(
      company: company,
      employee_ids: [ employee.id ],
      from: range_from,
      to: range_to
    )

    expect(result[employee.id]).to eq(0)
  end
end
