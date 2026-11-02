# frozen_string_literal: true

# Kpi::Scoring — shared row/score math for scorecards and leaderboards.
#
# Achievement is actual ÷ target (inverted for lower-is-better), expressed as a
# percentage and left uncapped so overachievement is visible. The composite is
# the weighted average across rows that have a target.
module Kpi
  module Scoring
    module_function

    def build_row(config, actual_value)
      {
        kpi_config_id: config.id,
        name: config.name,
        metric_key: config.metric_key,
        unit: config.metric.unit,
        direction: config.direction,
        target_value: config.target_value&.to_f,
        weight: config.weight.to_f,
        actual_value: actual_value,
        achievement_pct: achievement_pct(config, actual_value)
      }
    end

    def composite_pct(rows)
      scored_rows = rows.select { |row| row[:achievement_pct].present? }
      total_weight = scored_rows.sum { |row| row[:weight] }
      return nil if total_weight.zero?

      (scored_rows.sum { |row| row[:achievement_pct] * row[:weight] } / total_weight).to_f.round(1)
    end

    def achievement_pct(config, actual_value)
      return nil if config.target_value.nil?

      target = config.target_value.to_d
      actual = actual_value.to_d

      if config.direction_lower_better?
        return 100.0 if actual <= 0

        ((target / actual) * 100).to_f.round(1)
      else
        return 100.0 if target <= 0

        ((actual / target) * 100).to_f.round(1)
      end
    end
  end
end
