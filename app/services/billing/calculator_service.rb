# frozen_string_literal: true

# Computes the total monthly charge for a company by summing three components:
#   1. Base price    — contract.fixed_monthly_price_cents
#   2. Features      — sum of contract_features.active.monthly_flat_price_cents,
#                      prorated by the number of calendar days the company was
#                      actually accessible (DailyActiveLog count for the period)
#   3. Overages      — usage above free_allowance × unit_price_cents
#                      (NOT prorated: pure usage-based via DailyUsageLog)
#
# Add-on Feature proration rules:
#   active_days = 0                → $0 (company was suspended all month)
#   active_days >= days_in_period  → full monthly total (exact advertised price)
#   otherwise                      → (monthly_flat_price × active_days) / days_in_period
#
#   result = CalculatorService.call(company)
#   result.total_cents          # => 1500 (i.e. $15.00)
#   result.breakdown.base_cents      # => 0
#   result.breakdown.features_cents  # => 500  (full month — exact advertised price)
#   result.breakdown.active_days     # => 31
#   result.breakdown.days_in_period  # => 31
#   result.breakdown.overages        # => { "orders" => 1000 }
#
module Billing
  class CalculatorService
    Result = Struct.new(:total_cents, :breakdown, keyword_init: true) do
      def initialize(total_cents: 0, breakdown: {})
        super
      end
    end

    Breakdown = Struct.new(:base_cents, :features_cents, :overages,
                           :active_days, :days_in_period, keyword_init: true) do
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
      active_days = compute_active_days
      days_in_period = (period_end.to_date - period_start.to_date).to_i + 1
      features_cents = compute_prorated_features(contract, active_days, days_in_period)
      overages = compute_overages(contract)

      breakdown = Breakdown.new(
        base_cents: base_cents,
        features_cents: features_cents,
        overages: overages,
        active_days: active_days,
        days_in_period: days_in_period
      )

      Result.new(total_cents: breakdown.total_cents, breakdown: breakdown)
    end

    private

    attr_reader :company, :period_start, :period_end

    def zero_result
      Result.new
    end

    def compute_active_days
      DailyActiveLog.where(company: company)
                   .for_period(period_start.to_date, period_end.to_date)
                   .count
    end

    def compute_prorated_features(contract, active_days, days_in_period)
      active_features = contract.contract_features.active.to_a
      return 0 if active_features.empty?
      return 0 if active_days.zero?

      # Full-month bypass: guarantees the exact advertised price (no rounding drift).
      # e.g. monthly_flat_price 300 cents passed through unmodified for a 30-day month.
      return active_features.sum(&:monthly_flat_price_cents) if active_days >= days_in_period

      # Prorated: (monthly × active_days) / days_in_period  (integer division → cents)
      active_features.sum do |feature|
        (feature.monthly_flat_price_cents * active_days) / days_in_period
      end
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
