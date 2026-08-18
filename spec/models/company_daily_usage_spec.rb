# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyDailyUsage, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
  end

  describe "validations" do
    it { should validate_presence_of(:usage_date) }
  end

  describe "hourly helpers" do
    let(:company) { create(:company) }
    let(:usage) { CompanyDailyUsage.find_or_create_for(company, Date.new(2026, 8, 18)) }

    it "returns 0 for empty hour slots" do
      expect(usage.hour_usage(0)).to eq(0)
      expect(usage.hour_usage(23)).to eq(0)
    end

    it "sets and reads hour slots" do
      usage.set_hour_usage(14, 10)
      expect(usage.hour_usage(14)).to eq(10)
      expect(usage.reload.hour_usage(14)).to eq(10)
    end

    it "adds deltas to hour slots" do
      usage.add_hour_usage(14, 10)
      usage.add_hour_usage(14, 5)
      expect(usage.hour_usage(14)).to eq(15)
    end

    it "sums total credits across hours" do
      usage.add_hour_usage(9, 10)
      usage.add_hour_usage(14, 15)
      expect(usage.total_credits).to eq(25)
    end

    it "starts with a zero total" do
      expect(usage.total_credits).to eq(0)
    end

    it "recomputes the total when a slot is overwritten" do
      usage.add_hour_usage(9, 10)
      usage.add_hour_usage(14, 15)
      usage.set_hour_usage(9, 100)
      expect(usage.reload.total_credits).to eq(115)
    end

    it "rejects out-of-range hours" do
      expect { usage.hour_usage(24) }.to raise_error(ArgumentError)
      expect { usage.set_hour_usage(-1, 5) }.to raise_error(ArgumentError)
      expect { usage.add_hour_usage(24, 5) }.to raise_error(ArgumentError)
    end
  end
end
