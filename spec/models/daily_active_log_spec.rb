# frozen_string_literal: true

require "rails_helper"

RSpec.describe DailyActiveLog, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:company) }
  end

  describe "validations" do
    subject { build(:daily_active_log) }
    it { is_expected.to validate_presence_of(:log_date) }
    it { is_expected.to validate_uniqueness_of(:log_date).scoped_to(:company_id) }
  end

  describe ".for_period scope" do
    let(:company) { create(:company) }
    let(:start_date) { Date.new(2026, 6, 1) }
    let(:end_date) { Date.new(2026, 6, 30) }

    before do
      create(:daily_active_log, company: company, log_date: Date.new(2026, 5, 28))  # before period
      create(:daily_active_log, company: company, log_date: Date.new(2026, 6, 15))  # inside
      create(:daily_active_log, company: company, log_date: Date.new(2026, 6, 30))  # boundary
      create(:daily_active_log, company: company, log_date: Date.new(2026, 7, 1))   # after period
    end

    it "returns logs within [start_date, end_date] inclusive" do
      expect(DailyActiveLog.for_period(start_date, end_date).count).to eq(2)
    end

    it "excludes logs outside the period" do
      results = DailyActiveLog.for_period(start_date, end_date).pluck(:log_date)
      expect(results).not_to include(Date.new(2026, 5, 28))
      expect(results).not_to include(Date.new(2026, 7, 1))
    end
  end

  describe "uniqueness on [company_id, log_date]" do
    let(:company) { create(:company) }
    let(:log_date) { Date.current }

    it "allows the same date for different companies" do
      create(:daily_active_log, company: company, log_date: log_date)
      other = create(:company)
      expect { create(:daily_active_log, company: other, log_date: log_date) }
        .not_to raise_error
    end

    it "allows different dates for the same company" do
      create(:daily_active_log, company: company, log_date: log_date)
      expect { create(:daily_active_log, company: company, log_date: log_date + 1.day) }
        .not_to raise_error
    end
  end
end
