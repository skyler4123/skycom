# frozen_string_literal: true

require "rails_helper"

RSpec.describe DailyFeatureLog, type: :model do
  subject(:log) { build(:daily_feature_log) }

  it { is_expected.to belong_to(:company) }
  it { is_expected.to belong_to(:contract_feature) }

  it { is_expected.to validate_presence_of(:log_date) }
  it { is_expected.to validate_uniqueness_of(:log_date).scoped_to(%i[company_id contract_feature_id]) }

  describe ".for_period scope" do
    let(:company) { create(:company) }
    let(:contract_feature) { create(:contract_feature) }
    let(:start_date) { Date.new(2026, 6, 1) }
    let(:end_date) { Date.new(2026, 6, 30) }

    before do
      create(:daily_feature_log, company: company, contract_feature: contract_feature, log_date: Date.new(2026, 5, 31))
      create(:daily_feature_log, company: company, contract_feature: contract_feature, log_date: Date.new(2026, 6, 15))
      create(:daily_feature_log, company: company, contract_feature: contract_feature, log_date: Date.new(2026, 6, 30))
      create(:daily_feature_log, company: company, contract_feature: contract_feature, log_date: Date.new(2026, 7, 1))
    end

    it "returns records within the date range" do
      expect(described_class.for_period(start_date, end_date).count).to eq(2)
    end

    it "excludes records before the range" do
      results = described_class.for_period(start_date, end_date).pluck(:log_date)
      expect(results).not_to include(Date.new(2026, 5, 31))
    end

    it "excludes records after the range" do
      results = described_class.for_period(start_date, end_date).pluck(:log_date)
      expect(results).not_to include(Date.new(2026, 7, 1))
    end
  end

  describe "uniqueness constraint" do
    let(:company) { create(:company) }
    let(:contract_feature) { create(:contract_feature) }
    let(:log_date) { Date.current }

    it "allows same date for different companies" do
      other = create(:company)
      create(:daily_feature_log, company: company, contract_feature: contract_feature, log_date: log_date)
      expect do
        create(:daily_feature_log, company: other, contract_feature: contract_feature, log_date: log_date)
      end.not_to raise_error
    end

    it "allows different dates for same company and feature" do
      create(:daily_feature_log, company: company, contract_feature: contract_feature, log_date: log_date)
      expect do
        create(:daily_feature_log, company: company, contract_feature: contract_feature, log_date: log_date + 1.day)
      end.not_to raise_error
    end
  end
end
