# frozen_string_literal: true

module Billing
  class CalculatorService
    Result = Struct.new(:total_cents, :breakdown, keyword_init: true) do
      def initialize(total_cents: 0, breakdown: {})
        super
      end
    end

    Breakdown = Struct.new(:base_cents, :features_cents, :overages, keyword_init: true) do
      def total_cents
        base_cents.to_i + features_cents.to_i + overages.values.sum
      end
    end

    def self.call(company, period_start: nil, period_end: nil)
      new(company, period_start: period_start, period_end: period_end).call
    end

    def initialize(company, period_start: nil, period_end: nil)
      @company = company
      @period_start = period_start || 1.month.ago.beginning_of_month
      @period_end = period_end || 1.month.ago.end_of_month
    end

    def call
      contract = company.active_billing_contract
      return zero_result unless contract

      base_cents = contract.fixed_monthly_price_cents
      features_cents = contract.contract_features.active.sum(:monthly_flat_price_cents)
      overages = compute_overages(contract)

      breakdown = Breakdown.new(
        base_cents: base_cents,
        features_cents: features_cents,
        overages: overages
      )

      Result.new(total_cents: breakdown.total_cents, breakdown: breakdown)
    end

    private

    attr_reader :company, :period_start, :period_end

    def zero_result
      Result.new
    end

    def compute_overages(contract)
      contract.contract_metrics.active.each_with_object({}) do |metric, hash|
        actual = DailyUsageLog.where(company: company, billing_resource: metric.billing_resource)
                              .for_period(period_start, period_end)
                              .sum(:usage_count)

        next unless actual > metric.free_allowance

        overage_units = actual - metric.free_allowance
        hash[metric.billing_resource.name] = overage_units * metric.unit_price_cents
      end
    end
  end
end
