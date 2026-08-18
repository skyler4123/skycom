# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyUsageSyncJob do
  describe "#perform" do
    include ActiveSupport::Testing::TimeHelpers

    let(:company) { create(:company) }
    let(:today) { Date.new(2026, 8, 18) }

    before do
      travel_to(Time.zone.local(2026, 8, 18, 9, 30)) { company.record_credit_usage!(10) }
      travel_to(Time.zone.local(2026, 8, 18, 14, 30)) { company.record_credit_usage!(15) }
    end

    it "persists hourly deltas into CompanyDailyUsage and resets the hourly counters" do
      travel_to(Time.zone.local(2026, 8, 18, 23, 0)) do
        expect {
          described_class.perform_now
        }.to change(CompanyDailyUsage, :count).by(1)
      end

      daily = CompanyDailyUsage.find_by!(company: company, usage_date: today)
      expect(daily.hour_usage(9)).to eq(10)
      expect(daily.hour_usage(14)).to eq(15)
      expect(daily.total_credits).to eq(25)

      expect(company.credit_usage_hour_9.value).to eq(0)
      expect(company.credit_usage_hour_14.value).to eq(0)
    end

    it "persists the daily delta into CompanyMonthlyUsage and resets the daily counter" do
      travel_to(Time.zone.local(2026, 8, 18, 23, 0)) do
        expect {
          described_class.perform_now
        }.to change(CompanyMonthlyUsage, :count).by(1)
      end

      monthly = CompanyMonthlyUsage.find_by!(company: company, usage_month: today.beginning_of_month)
      expect(monthly.day_usage(today.day)).to eq(25)
      expect(company.credit_usage_daily.value).to eq(0)
    end

    it "is idempotent" do
      travel_to(Time.zone.local(2026, 8, 18, 23, 0)) do
        described_class.perform_now
      end
      daily = CompanyDailyUsage.find_by!(company: company, usage_date: today)

      expect {
        travel_to(Time.zone.local(2026, 8, 18, 23, 30)) { described_class.perform_now }
      }.not_to change(CompanyDailyUsage, :count)
      expect(daily.reload.total_credits).to eq(25)
    end

    it "does not raise when one company fails" do
      allow(CompanyDailyUsage).to receive(:find_or_create_for).and_raise(StandardError, "boom")

      travel_to(Time.zone.local(2026, 8, 18, 23, 0)) do
        expect { described_class.perform_now }.not_to raise_error
      end
    end
  end
end
