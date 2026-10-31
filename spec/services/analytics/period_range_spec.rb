# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analytics::PeriodRange do
  include ActiveSupport::Testing::TimeHelpers

  around do |example|
    travel_to(Time.zone.local(2026, 10, 31, 12, 0, 0)) { example.run }
  end

  describe "#current_range" do
    it "uses the current month through now for this_month" do
      range = described_class.new("this_month")

      expect(range.key).to eq("this_month")
      expect(range.current_range.begin).to eq(Time.zone.local(2026, 10, 1))
      expect(range.current_range.end).to be_within(1.second).of(Time.zone.local(2026, 10, 31, 12))
    end

    it "uses the previous calendar month for last_month" do
      range = described_class.new("last_month")

      expect(range.current_range.begin).to eq(Time.zone.local(2026, 9, 1))
      expect(range.current_range.end).to be_within(1.second).of(Time.zone.local(2026, 9, 30, 23, 59, 59))
    end

    it "uses six months through now for last_6_months" do
      range = described_class.new("last_6_months")

      expect(range.current_range.begin).to eq(Time.zone.local(2026, 5, 1))
      expect(range.current_range.end).to be_within(1.second).of(Time.zone.local(2026, 10, 31, 12))
    end

    it "uses the year through now for this_year" do
      range = described_class.new("this_year")

      expect(range.current_range.begin).to eq(Time.zone.local(2026, 1, 1))
      expect(range.current_range.end).to be_within(1.second).of(Time.zone.local(2026, 10, 31, 12))
    end
  end

  describe "#previous_range" do
    it "compares this_month against the same day span last month" do
      range = described_class.new("this_month")

      expect(range.previous_range.begin).to eq(Time.zone.local(2026, 9, 1))
      expect(range.previous_range.end).to be_within(1.second).of(Time.zone.local(2026, 9, 30, 23, 59, 59))
    end

    it "compares last_month against the month before it" do
      range = described_class.new("last_month")

      expect(range.previous_range.begin).to eq(Time.zone.local(2026, 8, 1))
      expect(range.previous_range.end).to be_within(1.second).of(Time.zone.local(2026, 8, 31, 23, 59, 59))
    end

    it "compares last_6_months against the six months before it" do
      range = described_class.new("last_6_months")

      expect(range.previous_range.begin).to eq(Time.zone.local(2025, 11, 1))
      expect(range.previous_range.end).to be_within(1.second).of(Time.zone.local(2026, 4, 30, 23, 59, 59))
    end

    it "compares this_year against the same span last year" do
      range = described_class.new("this_year")

      expect(range.previous_range.begin).to eq(Time.zone.local(2025, 1, 1))
      expect(range.previous_range.end).to be_within(1.second).of(Time.zone.local(2025, 10, 31, 12))
    end
  end

  it "falls back to this_month for an unknown period" do
    range = described_class.new("not_a_period")

    expect(range.key).to eq("this_month")
    expect(range.current_range.begin).to eq(Time.zone.local(2026, 10, 1))
  end
end
