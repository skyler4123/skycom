require "rails_helper"

RSpec.describe Kpi::PeriodRange do
  around do |example|
    travel_to(Time.zone.parse("2026-03-15 12:00:00")) { example.run }
  end

  it "defaults to the current month" do
    range = described_class.new(period: nil)

    expect(range.key).to eq("this_month")
    expect(range.from).to eq(Time.zone.parse("2026-03-01 00:00:00"))
    expect(range.to).to eq(Time.zone.parse("2026-03-31").end_of_day)
  end

  it "builds the previous month" do
    range = described_class.new(period: "last_month")

    expect(range.from).to eq(Time.zone.parse("2026-02-01 00:00:00"))
    expect(range.to).to eq(Time.zone.parse("2026-02-28").end_of_day)
  end

  it "builds the current quarter" do
    range = described_class.new(period: "this_quarter")

    expect(range.from).to eq(Time.zone.parse("2026-01-01 00:00:00"))
    expect(range.to).to eq(Time.zone.parse("2026-03-31").end_of_day)
  end

  it "accepts a custom range" do
    range = described_class.new(period: "custom", from: "2026-02-10", to: "2026-02-20")

    expect(range.key).to eq("custom")
    expect(range.from).to eq(Time.zone.parse("2026-02-10 00:00:00"))
    expect(range.to).to eq(Time.zone.parse("2026-02-20").end_of_day)
  end

  it "falls back to the current month for invalid input" do
    range = described_class.new(period: "custom", from: "not-a-date", to: nil)

    expect(range.key).to eq("this_month")
  end
end
