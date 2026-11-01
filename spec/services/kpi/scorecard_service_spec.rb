require "rails_helper"

RSpec.describe Kpi::ScorecardService do
  let(:company) { create(:company) }
  let(:employee) { create(:employee, company: company) }
  let(:range_from) { Time.zone.parse("2026-03-01 00:00:00") }
  let(:range_to) { Time.zone.parse("2026-03-31 23:59:59") }
  let(:in_range) { Time.zone.parse("2026-03-15 10:00:00") }

  def call_service
    described_class.call(company: company, employee: employee, from: range_from, to: range_to)
  end

  it "returns raw values, achievement, and a weighted composite" do
    create(:kpi_config, company: company, name: "Orders", metric_key: "orders_count", target_value: 10, weight: 1)
    create(:kpi_config, company: company, name: "Revenue", metric_key: "orders_revenue_cents", target_value: 60_000, weight: 3)
    12.times { create_paid_order(company: company, salesperson: employee, created_at: in_range, total_price: 50.0) }

    result = call_service

    orders_row = result[:rows].find { |row| row[:name] == "Orders" }
    revenue_row = result[:rows].find { |row| row[:name] == "Revenue" }

    expect(orders_row[:actual_value]).to eq(12)
    expect(orders_row[:achievement_pct]).to eq(120.0)
    expect(revenue_row[:actual_value]).to eq(60_000)
    expect(revenue_row[:achievement_pct]).to eq(100.0)
    expect(result[:composite_pct]).to eq(105.0)
  end

  it "shows the raw value without scoring when no target is set" do
    create(:kpi_config, company: company, name: "Orders", metric_key: "orders_count", target_value: nil)
    3.times { create_paid_order(company: company, salesperson: employee, created_at: in_range) }

    result = call_service

    expect(result[:rows].first[:actual_value]).to eq(3)
    expect(result[:rows].first[:achievement_pct]).to be_nil
    expect(result[:composite_pct]).to be_nil
  end

  it "inverts achievement for lower-is-better metrics" do
    create(:kpi_config, company: company, name: "Orders", metric_key: "orders_count",
      target_value: 10, direction: :lower_better)
    5.times { create_paid_order(company: company, salesperson: employee, created_at: in_range) }

    result = call_service

    expect(result[:rows].first[:achievement_pct]).to eq(200.0)
  end

  it "excludes configs whose scope does not match the employee" do
    create(:kpi_config, company: company, name: "Other category", metric_key: "orders_count",
      target_value: 10, category: create(:category, company: company))

    expect(call_service[:rows]).to be_empty
  end

  it "counts only orders sold by the employee" do
    coworker = create(:employee, company: company)
    create(:kpi_config, company: company, name: "Orders", metric_key: "orders_count", target_value: 10)
    create_paid_order(company: company, salesperson: employee, created_at: in_range)
    create_paid_order(company: company, salesperson: coworker, created_at: in_range)
    create_paid_order(company: company, salesperson: nil, created_at: in_range)

    result = call_service

    expect(result[:rows].first[:actual_value]).to eq(1)
  end
end
