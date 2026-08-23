# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyUsageSyncJob do
  describe "#perform" do
    include ActiveSupport::Testing::TimeHelpers

    let(:company) { create(:company) }
    let(:today) { Date.new(2026, 8, 18) }

    before do
      company.record_credit_usage!(10)
      company.record_credit_usage!(15)
    end

    it "persists the delta into CompanyDailyUsage's hour slot and resets the counter" do
      travel_to(Time.zone.local(2026, 8, 18, 14, 5)) do
        expect {
          described_class.perform_now
        }.to change(CompanyDailyUsage, :count).by(1)
      end

      daily = CompanyDailyUsage.find_by!(company: company, usage_date: today)
      expect(daily.hour_usage(14)).to eq(25)
      expect(daily.total_credits).to eq(25)
      expect(company.credit_usage.value).to eq(0)
    end

    it "persists the delta into CompanyMonthlyUsage's day slot and resets the counter" do
      travel_to(Time.zone.local(2026, 8, 18, 14, 5)) do
        expect {
          described_class.perform_now
        }.to change(CompanyMonthlyUsage, :count).by(1)
      end

      monthly = CompanyMonthlyUsage.find_by!(company: company, usage_month: today.beginning_of_month)
      expect(monthly.day_usage(18)).to eq(25)
      expect(monthly.total_credits).to eq(25)
      expect(company.credit_usage.value).to eq(0)
    end

    it "is idempotent" do
      travel_to(Time.zone.local(2026, 8, 18, 14, 5)) { described_class.perform_now }
      daily = CompanyDailyUsage.find_by!(company: company, usage_date: today)

      expect {
        travel_to(Time.zone.local(2026, 8, 18, 15, 5)) { described_class.perform_now }
      }.not_to change(CompanyDailyUsage, :count)
      expect(daily.reload.total_credits).to eq(25)
    end

    it "accumulates across drains like the 2H/6H example" do
      dedicated = create(:company)
      dedicated.record_credit_usage!(500)
      travel_to(Time.zone.local(2026, 8, 18, 14, 5)) { described_class.perform_now }

      daily = CompanyDailyUsage.find_by!(company: dedicated, usage_date: today)
      monthly = CompanyMonthlyUsage.find_by!(company: dedicated, usage_month: today.beginning_of_month)
      expect(daily.hour_usage(14)).to eq(500)
      expect(daily.total_credits).to eq(500)
      expect(monthly.day_usage(18)).to eq(500)
      expect(monthly.total_credits).to eq(500)
      expect(dedicated.credit_usage.value).to eq(0)

      dedicated.record_credit_usage!(400)
      travel_to(Time.zone.local(2026, 8, 18, 15, 5)) { described_class.perform_now }

      expect(daily.reload.hour_usage(15)).to eq(400)
      expect(daily.reload.total_credits).to eq(900)
      expect(monthly.reload.day_usage(18)).to eq(900)
      expect(monthly.reload.total_credits).to eq(900)
      expect(dedicated.credit_usage.value).to eq(0)
    end

    it "does not raise when one company fails" do
      allow(CompanyDailyUsage).to receive(:find_or_create_for).and_raise(StandardError, "boom")

      travel_to(Time.zone.local(2026, 8, 18, 14, 5)) do
        expect { described_class.perform_now }.not_to raise_error
      end
    end
  end
end
