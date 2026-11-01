require "rails_helper"

RSpec.describe Kpi::Metrics::OrdersCount do
  let(:company) { create(:company) }
  let(:employee) { create(:employee, company: company) }
  let(:coworker) { create(:employee, company: company) }
  let(:range_from) { Time.zone.parse("2026-03-01 00:00:00") }
  let(:range_to) { Time.zone.parse("2026-03-31 23:59:59") }
  let(:in_range) { Time.zone.parse("2026-03-15 10:00:00") }

  it "counts paid orders per salesperson in the period" do
    create_paid_order(company: company, salesperson: employee, created_at: in_range)
    create_paid_order(company: company, salesperson: employee, created_at: in_range + 1.day)
    create_paid_order(company: company, salesperson: coworker, created_at: in_range)

    result = described_class.call(
      company: company,
      employee_ids: [ employee.id, coworker.id ],
      from: range_from,
      to: range_to
    )

    expect(result[employee.id]).to eq(2)
    expect(result[coworker.id]).to eq(1)
  end

  it "returns zero for an employee with no orders" do
    result = described_class.call(
      company: company,
      employee_ids: [ employee.id ],
      from: range_from,
      to: range_to
    )

    expect(result[employee.id]).to eq(0)
  end

  it "excludes unpaid, discarded, and out-of-range orders" do
    create_paid_order(company: company, salesperson: employee, created_at: in_range, workflow_status: :pending)
    create_paid_order(company: company, salesperson: employee, created_at: in_range)
      .update_columns(discarded_at: Time.current)
    create_paid_order(company: company, salesperson: employee, created_at: in_range - 1.month)

    result = described_class.call(
      company: company,
      employee_ids: [ employee.id ],
      from: range_from,
      to: range_to
    )

    expect(result[employee.id]).to eq(0)
  end

  it "does not count orders from another company" do
    other_company = create(:company)
    other_employee = create(:employee, company: other_company)
    create_paid_order(company: other_company, salesperson: other_employee, created_at: in_range)

    result = described_class.call(
      company: company,
      employee_ids: [ employee.id ],
      from: range_from,
      to: range_to
    )

    expect(result[employee.id]).to eq(0)
  end
end
