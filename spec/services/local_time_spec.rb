# frozen_string_literal: true

require "rails_helper"

RSpec.describe LocalTime, type: :service do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company, timezone: :plus_7) }

  it "reads the offset from a location record" do
    expect(described_class.offset_seconds(branch)).to eq(25_200)
    expect(described_class.offset_seconds("minus_5")).to eq(-18_000)
    expect(described_class.offset_seconds(nil)).to eq(0)
  end

  it "returns the location calendar day for a UTC instant" do
    expect(described_class.today(branch, at: Time.utc(2026, 11, 17, 18, 0, 0))).to eq(Date.new(2026, 11, 18))
  end

  it "builds a UTC range for the location calendar day" do
    range = described_class.day_range(Date.new(2026, 11, 17), branch)

    expect(range.begin).to eq(Time.utc(2026, 11, 16, 17, 0, 0))
    expect(range.end).to eq(Time.utc(2026, 11, 17, 17, 0, 0))
  end

  it "parses a wall-clock date and time in the location timezone" do
    parsed = described_class.parse(Date.new(2026, 11, 17), "14:00", branch)

    expect(parsed).to eq(Time.utc(2026, 11, 17, 7, 0, 0))
  end

  it "returns nil for blank or invalid input" do
    expect(described_class.parse(nil, "14:00", branch)).to be_nil
    expect(described_class.parse(Date.new(2026, 11, 17), "", branch)).to be_nil
    expect(described_class.parse(Date.new(2026, 11, 17), "not-a-time", branch)).to be_nil
  end
end
