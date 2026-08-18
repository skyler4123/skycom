# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyUsageSyncJob do
  describe "#perform" do
    let(:company) { create(:company) }
    let(:today) { Time.current.to_date }

    before do
      company.record_credit_usage!(10, at: Time.current.change(hour: 9))
      company.record_credit_usage!(15, at: Time.current.change(hour: 14))
    end

    it "persists hourly deltas into CompanyDailyUsage and resets the hourly counters" do
      expect {
        described_class.perform_now
      }.to change(CompanyDailyUsage, :count).by(1)

      daily = CompanyDailyUsage.find_by!(company: company, usage_date: today)
      expect(daily.hour_usage(9)).to eq(10)
      expect(daily.hour_usage(14)).to eq(15)
      expect(daily.total_credits).to eq(25)

      expect(Kredis.counter(Company.credit_usage_hour_key(company.id, today, 9)).value).to eq(0)
      expect(Kredis.counter(Company.credit_usage_hour_key(company.id, today, 14)).value).to eq(0)
    end

    it "persists the daily delta into CompanyMonthlyUsage and resets the daily counter" do
      expect {
        described_class.perform_now
      }.to change(CompanyMonthlyUsage, :count).by(1)

      monthly = CompanyMonthlyUsage.find_by!(company: company, usage_month: today.beginning_of_month)
      expect(monthly.day_usage(today.day)).to eq(25)
      expect(Kredis.counter(Company.credit_usage_day_key(company.id, today)).value).to eq(0)
    end

    it "is idempotent" do
      described_class.perform_now
      daily = CompanyDailyUsage.find_by!(company: company, usage_date: today)

      expect {
        described_class.perform_now
      }.not_to change(CompanyDailyUsage, :count)
      expect(daily.reload.total_credits).to eq(25)
    end

    it "does not raise when one company fails" do
      allow(CompanyDailyUsage).to receive(:find_or_create_for).and_raise(StandardError, "boom")

      expect { described_class.perform_now }.not_to raise_error
    end
  end
end
