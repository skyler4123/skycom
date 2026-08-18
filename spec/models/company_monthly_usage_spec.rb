# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyMonthlyUsage, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
  end

  describe "validations" do
    it { should validate_presence_of(:usage_month) }
  end

  describe ".find_or_create_for" do
    let(:company) { create(:company) }

    it "creates one row per company/month and returns it on re-fetch" do
      first = CompanyMonthlyUsage.find_or_create_for(company, Date.new(2026, 8, 1))
      second = CompanyMonthlyUsage.find_or_create_for(company, Date.new(2026, 8, 1))
      expect(first).to eq(second)
      expect(CompanyMonthlyUsage.count).to eq(1)
    end
  end

  describe "daily helpers" do
    let(:company) { create(:company) }
    let(:usage) { CompanyMonthlyUsage.find_or_create_for(company, Date.new(2026, 8, 1)) }

    it "persists day values into metadata via store_accessor" do
      usage.set_day_usage(15, 120)
      expect(usage.metadata["d15"]).to eq(120)
    end

    it "returns 0 for empty day slots" do
      expect(usage.day_usage(1)).to eq(0)
      expect(usage.day_usage(31)).to eq(0)
    end

    it "sets and reads day slots" do
      usage.set_day_usage(15, 120)
      expect(usage.day_usage(15)).to eq(120)
      expect(usage.reload.day_usage(15)).to eq(120)
    end

    it "adds deltas to day slots" do
      usage.add_day_usage(15, 100)
      usage.add_day_usage(15, 20)
      expect(usage.day_usage(15)).to eq(120)
    end

    it "sums total credits across days" do
      usage.add_day_usage(1, 25)
      usage.add_day_usage(2, 30)
      expect(usage.total_credits).to eq(55)
    end

    it "starts with a zero total" do
      expect(usage.total_credits).to eq(0)
    end

    it "recomputes the total when a slot is overwritten" do
      usage.add_day_usage(1, 25)
      usage.add_day_usage(2, 30)
      usage.set_day_usage(1, 100)
      expect(usage.reload.total_credits).to eq(130)
    end

    it "rejects out-of-range days" do
      expect { usage.day_usage(0) }.to raise_error(ArgumentError)
      expect { usage.set_day_usage(32, 5) }.to raise_error(ArgumentError)
      expect { usage.add_day_usage(0, 5) }.to raise_error(ArgumentError)
    end
  end
end
