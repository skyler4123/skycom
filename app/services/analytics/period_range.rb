# frozen_string_literal: true

# Analytics::PeriodRange — derives the selected reporting window and the
# matching previous window used for delta comparisons.
#
# Single source of truth for analytics period math. The period keys match
# CacheKeyService::ANALYTICS_PERIODS; unknown values fall back to this_month.
module Analytics
  class PeriodRange
    PERIODS = %w[this_month last_month last_6_months this_year].freeze

    attr_reader :key, :current_range, :previous_range

    def initialize(period)
      @key = PERIODS.include?(period.to_s) ? period.to_s : "this_month"
      @current_range, @previous_range = build_ranges
    end

    private

    def build_ranges
      now = Time.current

      case key
      when "last_month"
        current_start = 1.month.ago.beginning_of_month
        current_end = 1.month.ago.end_of_month
        previous_start = (current_start - 1.month).beginning_of_month
        previous_end = current_start - 1.second
      when "last_6_months"
        current_start = now.beginning_of_month - 5.months
        current_end = now
        previous_start = current_start - 6.months
        previous_end = current_start - 1.second
      when "this_year"
        current_start = now.beginning_of_year
        current_end = now
        previous_start = 1.year.ago.beginning_of_year
        previous_end = 1.year.ago
      else
        current_start = now.beginning_of_month
        current_end = now
        previous_start = 1.month.ago.beginning_of_month
        previous_end = 1.month.ago.end_of_month
      end

      [ current_start..current_end, previous_start..previous_end ]
    end
  end
end
