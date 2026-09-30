# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarAvailabilityRule, type: :model do
  it { is_expected.to belong_to(:company) }
  it { is_expected.to belong_to(:calendar_practitioner).optional }
  it { is_expected.to belong_to(:calendar_location).optional }

  describe "validations" do
    # The owner must live in the same company as the rule — that is the whole
    # point of the guard — so share one company throughout.
    let(:company) { create(:company) }
    let(:practitioner) { create(:calendar_practitioner, company: company) }

    it "accepts a practitioner-owned rule" do
      expect(build(:calendar_availability_rule, company: company, calendar_practitioner: practitioner)).to be_valid
    end

    it "accepts a location-owned rule" do
      expect(build(:calendar_availability_location_rule, company: company,
        calendar_location: create(:calendar_location, company: company))).to be_valid
    end

    it "rejects a rule with no owner" do
      rule = build(:calendar_availability_rule, calendar_practitioner: nil)
      expect(rule).not_to be_valid
      expect(rule.errors[:base].join).to include("must belong to")
    end

    it "rejects a rule owned by both a practitioner and a location" do
      rule = build(:calendar_availability_rule, company: company,
        calendar_practitioner: practitioner, calendar_location: create(:calendar_location, company: company))
      expect(rule).not_to be_valid
      expect(rule.errors[:base].join).to include("not both")
    end

    it "rejects an end time at or before the start" do
      rule = build(:calendar_availability_rule, calendar_practitioner: practitioner,
        start_time: "17:00", end_time: "09:00")
      expect(rule).not_to be_valid
      expect(rule.errors[:end_time].join).to include("overnight")
    end

    it "rejects a malformed time" do
      expect(build(:calendar_availability_rule, start_time: "9am")).not_to be_valid
      expect(build(:calendar_availability_rule, end_time: "25:00")).not_to be_valid
    end

    it "rejects an owner from another company" do
      rule = build(:calendar_availability_rule, company: create(:company),
        calendar_practitioner: practitioner)
      expect(rule).not_to be_valid
      expect(rule.errors[:base].join).to include("same company")
    end
  end

  describe "#covers_weekday?" do
    subject(:rule) { build(:calendar_availability_rule, days_of_week: [ 1, 3, 5 ]) }

    it "is true on a listed weekday" do
      # 2026-01-05 is a Monday (wday 1).
      expect(rule.covers_weekday?(Date.new(2026, 1, 5))).to be(true)
    end

    it "is false on an unlisted weekday" do
      # 2026-01-06 is a Tuesday (wday 2).
      expect(rule.covers_weekday?(Date.new(2026, 1, 6))).to be(false)
    end

    it "treats an empty list as every day" do
      rule.days_of_week = []
      expect(rule.covers_weekday?(Date.new(2026, 1, 6))).to be(true)
    end
  end

  describe ".effective_on" do
    it "includes rules with no date bounds" do
      rule = create(:calendar_availability_rule)
      expect(described_class.effective_on(Date.current)).to include(rule)
    end

    it "excludes a rule whose window has passed" do
      rule = create(:calendar_availability_rule, effective_to: 1.day.ago)
      expect(described_class.effective_on(Date.current)).not_to include(rule)
    end

    it "excludes a rule that has not started" do
      rule = create(:calendar_availability_rule, effective_from: 1.day.from_now)
      expect(described_class.effective_on(Date.current)).not_to include(rule)
    end
  end

  it "labels a working window and a blackout differently" do
    working = create(:calendar_availability_rule)
    blackout = create(:calendar_availability_blackout)

    expect(working.working?).to be(true)
    expect(blackout.blackout?).to be(true)
  end

  describe "#to_s" do
    it "prefers the rule's own name" do
      rule = create(:calendar_availability_rule, name: "Morning clinic")
      expect(rule.to_s).to eq("Morning clinic")
    end

    it "falls back to owner and window when unnamed" do
      company = create(:company)
      practitioner = create(:calendar_practitioner, company: company)
      rule = create(:calendar_availability_rule, company: company,
        calendar_practitioner: practitioner, name: nil)

      expect(rule.to_s).to include(practitioner.name, "09:00", "17:00")
    end
  end
end
