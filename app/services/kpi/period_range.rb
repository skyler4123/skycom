# frozen_string_literal: true

# Resolves a KPI viewing window from a named preset or an explicit custom range.
# Unknown or incomplete input falls back to the current month.
module Kpi
  class PeriodRange
    PRESETS = %w[this_month last_month this_quarter last_quarter this_year].freeze

    attr_reader :key, :from, :to

    def initialize(period: nil, from: nil, to: nil)
      custom_from = parse_date(from)
      custom_to = parse_date(to)

      if period.to_s == "custom" && custom_from && custom_to && custom_from <= custom_to
        @key = "custom"
        @from = custom_from.beginning_of_day
        @to = custom_to.end_of_day
        return
      end

      @key = PRESETS.include?(period.to_s) ? period.to_s : "this_month"
      build_preset
    end

    private

    def parse_date(value)
      return nil if value.blank?

      Date.parse(value.to_s)
    rescue Date::Error
      nil
    end

    def build_preset
      now = Time.current

      case key
      when "last_month"
        last_month = 1.month.ago
        @from = last_month.beginning_of_month
        @to = last_month.end_of_month
      when "this_quarter"
        @from = now.beginning_of_quarter
        @to = now.end_of_quarter
      when "last_quarter"
        last_quarter = 3.months.ago
        @from = last_quarter.beginning_of_quarter
        @to = last_quarter.end_of_quarter
      when "this_year"
        @from = now.beginning_of_year
        @to = now.end_of_year
      else
        @from = now.beginning_of_month
        @to = now.end_of_month
      end
    end
  end
end
