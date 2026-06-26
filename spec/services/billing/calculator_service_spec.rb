# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::CalculatorService do
  subject(:result) { described_class.call(company) }

  let(:company) { create(:company) }
  let(:period_start) { 1.month.ago.beginning_of_month }
  let(:period_end) { 1.month.ago.end_of_month }

  # Auto-seeded free-tier contract (base=$0); update base price when needed
  let!(:contract) { company.active_billing_contract }

  # Helper: seed DailyFeatureLog rows for every day in the billing period
  # for a given feature, so the full-month proration bypass kicks in.
  def seed_full_month_feature(feature)
    (period_start.to_date..period_end.to_date).each do |day|
      create(:daily_feature_log, company: company, contract_feature: feature, log_date: day)
    end
  end

  before { contract.update!(start_date: 3.months.ago) }

  context "when contract has no features or metrics" do
    before { contract.update!(fixed_monthly_price_cents: 1000) }

    it "returns total_cents equal to base price" do
      expect(result.total_cents).to eq(1000)
    end

    it "includes base in breakdown" do
      expect(result.breakdown.base_cents).to eq(1000)
    end

    it "has zero features_cents" do
      expect(result.breakdown.features_cents).to eq(0)
    end

    it "has empty overages" do
      expect(result.breakdown.overages).to eq({})
    end
  end

  context "when contract has active features" do
    let!(:feature_resource) { create(:billing_resource, :addon_feature, name: "analytics_dashboard") }
    let!(:feature) do
      create(:contract_feature, billing_contract: contract,
             billing_resource: feature_resource, monthly_flat_price_cents: 500, lifecycle_status: :active)
    end

    before do
      contract.update!(fixed_monthly_price_cents: 1000)
      seed_full_month_feature(feature)
    end

    it "adds feature prices to total" do
      expect(result.total_cents).to eq(1500)
    end

    it "includes features in breakdown" do
      expect(result.breakdown.features_cents).to eq(500)
    end

    it "exposes days_in_period" do
      expect(result.breakdown.days_in_period).to be > 0
    end
  end

  context "when feature was disabled the entire month (zero feature-active days)" do
    let!(:feature_resource) { create(:billing_resource, :addon_feature, name: "analytics_dashboard") }

    before do
      contract.update!(fixed_monthly_price_cents: 1000)
      create(:contract_feature, billing_contract: contract,
             billing_resource: feature_resource, monthly_flat_price_cents: 500, lifecycle_status: :active)
      # No DailyFeatureLog records — feature was never enabled or company was suspended
    end

    it "charges $0 for features" do
      expect(result.breakdown.features_cents).to eq(0)
    end

    it "charges only base price" do
      expect(result.total_cents).to eq(1000)
    end
  end

  context "when company was active for half the month (per-feature proration)" do
    let!(:feature_resource) { create(:billing_resource, :addon_feature, name: "analytics_dashboard") }
    let!(:feature) do
      create(:contract_feature, billing_contract: contract,
             billing_resource: feature_resource, monthly_flat_price_cents: 500, lifecycle_status: :active)
    end

    let(:days_in_period) { (period_end.to_date - period_start.to_date).to_i + 1 }
    let(:feature_active_days) { days_in_period / 2 }
    let(:expected_features_cents) { (500 * feature_active_days) / days_in_period }

    before do
      contract.update!(fixed_monthly_price_cents: 1000)

      # Seed only `feature_active_days` rows (first half of the month)
      feature_active_days.times do |i|
        create(:daily_feature_log, company: company, contract_feature: feature,
               log_date: period_start.to_date + i.days)
      end
    end

    it "prorates feature charges by feature_active_days" do
      expect(result.breakdown.features_cents).to eq(expected_features_cents)
    end

    it "reports the full days_in_period" do
      expect(result.breakdown.days_in_period).to eq(days_in_period)
    end

    it "does not apply the full-month bypass" do
      expect(result.breakdown.features_cents).to be < 500
    end
  end

  context "when features have different active-day counts" do
    let!(:feature_a_resource) { create(:billing_resource, :addon_feature, name: "analytics_dashboard") }
    let!(:feature_b_resource) { create(:billing_resource, :addon_feature, name: "inventory_advanced") }
    let!(:feature_a) do
      create(:contract_feature, billing_contract: contract,
             billing_resource: feature_a_resource, monthly_flat_price_cents: 500, lifecycle_status: :active)
    end
    let!(:feature_b) do
      create(:contract_feature, billing_contract: contract,
             billing_resource: feature_b_resource, monthly_flat_price_cents: 300, lifecycle_status: :active)
    end

    let(:days_in_period) { (period_end.to_date - period_start.to_date).to_i + 1 }

    before do
      contract.update!(fixed_monthly_price_cents: 0)

      # Feature A: active all month (full price)
      (period_start.to_date..period_end.to_date).each do |day|
        create(:daily_feature_log, company: company, contract_feature: feature_a, log_date: day)
      end

      # Feature B: active only last 5 days (prorated)
      5.times do |i|
        create(:daily_feature_log, company: company, contract_feature: feature_b,
               log_date: period_end.to_date - i.days)
      end
    end

    it "charges full price for feature A" do
      expect(result.breakdown.features_cents).to be >= 500
    end

    it "charges less for feature B than full price" do
      total_features = result.breakdown.features_cents
      feature_b_portion = total_features - 500
      expect(feature_b_portion).to be < 300
      expect(feature_b_portion).to eq((300 * 5) / days_in_period)
    end
  end

  context "when contract has usage overages" do
    let!(:metric_resource) { create(:billing_resource, :volumetric, name: "orders") }

    before do
      contract.update!(fixed_monthly_price_cents: 1000)
      create(:contract_metric, billing_contract: contract,
             billing_resource: metric_resource, free_allowance: 100, unit_price_cents: 10)

      create(:daily_metric_log, company: company, billing_resource: metric_resource,
             usage_count: 50, log_date: period_start + 5.days)
      create(:daily_metric_log, company: company, billing_resource: metric_resource,
             usage_count: 70, log_date: period_start + 15.days)
    end

    it "charges for overage above free allowance" do
      expect(result.breakdown.overages["orders"]).to eq(200)
    end

    it "includes overage in total" do
      expect(result.total_cents).to eq(1200)
    end
  end

  context "when usage is within free allowance" do
    let!(:metric_resource) { create(:billing_resource, :volumetric, name: "orders") }

    before do
      contract.update!(fixed_monthly_price_cents: 1000)
      create(:contract_metric, billing_contract: contract,
             billing_resource: metric_resource, free_allowance: 100, unit_price_cents: 10)

      create(:daily_metric_log, company: company, billing_resource: metric_resource,
             usage_count: 30, log_date: period_start + 5.days)
    end

    it "does not charge overage" do
      expect(result.breakdown.overages).to eq({})
    end

    it "total is just base price" do
      expect(result.total_cents).to eq(1000)
    end
  end

  context "when no active contract exists" do
    before { contract.update!(lifecycle_status: :expired) }

    it "returns zero result" do
      expect(result.total_cents).to eq(0)
    end
  end
end
