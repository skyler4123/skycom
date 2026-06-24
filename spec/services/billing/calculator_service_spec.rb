# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::CalculatorService do
  subject(:result) { described_class.call(company) }

  let(:company) { create(:company) }
  let(:period_start) { 1.month.ago.beginning_of_month }
  let(:period_end) { 1.month.ago.end_of_month }

  let!(:contract) do
    create(:billing_contract, company: company, lifecycle_status: :active,
           start_date: 3.months.ago, fixed_monthly_price_cents: 1000)
  end

  context "when contract has no features or metrics" do
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

    before do
      create(:contract_feature, billing_contract: contract,
             billing_resource: feature_resource, monthly_flat_price_cents: 500, lifecycle_status: :active)
    end

    it "adds feature prices to total" do
      expect(result.total_cents).to eq(1500)
    end

    it "includes features in breakdown" do
      expect(result.breakdown.features_cents).to eq(500)
    end
  end

  context "when contract has usage overages" do
    let!(:metric_resource) { create(:billing_resource, :volumetric, name: "orders") }

    before do
      create(:contract_metric, billing_contract: contract,
             billing_resource: metric_resource, free_allowance: 100, unit_price_cents: 10)

      create(:daily_usage_log, company: company, billing_resource: metric_resource,
             usage_count: 50, log_date: period_start + 5.days)
      create(:daily_usage_log, company: company, billing_resource: metric_resource,
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
      create(:contract_metric, billing_contract: contract,
             billing_resource: metric_resource, free_allowance: 100, unit_price_cents: 10)

      create(:daily_usage_log, company: company, billing_resource: metric_resource,
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
