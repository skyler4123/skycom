require "rails_helper"

RSpec.describe Kpi::LeaderboardService do
  let(:company) { create(:company) }
  let(:employee) { create(:employee, company: company) }
  let(:coworker) { create(:employee, company: company) }
  let(:range_from) { Time.zone.parse("2026-03-01 00:00:00") }
  let(:range_to) { Time.zone.parse("2026-03-31 23:59:59") }
  let(:in_range) { Time.zone.parse("2026-03-15 10:00:00") }

  it "scores every employee and sorts by composite descending" do
    create(:kpi_config, company: company, name: "Orders", metric_key: "orders_count", target_value: 10)
    12.times { create_paid_order(company: company, salesperson: employee, created_at: in_range) }
    5.times { create_paid_order(company: company, salesperson: coworker, created_at: in_range) }

    result = described_class.call(company: company, from: range_from, to: range_to)

    ids = result[:rows].map { |row| row[:employee_id] }
    expect(ids.index(employee.id)).to be < ids.index(coworker.id)
    expect(result[:rows].find { |row| row[:employee_id] == employee.id }[:composite_pct]).to eq(120.0)
    expect(result[:rows].find { |row| row[:employee_id] == coworker.id }[:composite_pct]).to eq(50.0)
  end

  it "reports paid orders with no salesperson as unattributed" do
    create_paid_order(company: company, salesperson: nil, created_at: in_range, total_price: 50.0)
    create_paid_order(company: company, salesperson: nil, created_at: in_range, total_price: 25.0)

    result = described_class.call(company: company, from: range_from, to: range_to)

    expect(result[:unattributed][:orders_count]).to eq(2)
    expect(result[:unattributed][:revenue_cents]).to eq(7500)
  end

  it "excludes employees from another company" do
    other_company = create(:company)
    other_employee = create(:employee, company: other_company)

    result = described_class.call(company: company, from: range_from, to: range_to)

    expect(result[:rows].map { |row| row[:employee_id] }).not_to include(other_employee.id)
  end

  it "ignores orders outside the period" do
    create(:kpi_config, company: company, name: "Orders", metric_key: "orders_count", target_value: 10)
    create_paid_order(company: company, salesperson: employee, created_at: in_range - 1.month)

    result = described_class.call(company: company, from: range_from, to: range_to)
    row = result[:rows].find { |candidate| candidate[:employee_id] == employee.id }

    expect(row[:composite_pct]).to eq(0.0)
  end
end
