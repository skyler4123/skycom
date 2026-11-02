# frozen_string_literal: true

# Builds one employee's KPI scorecard for a date range: every active config
# whose scope matches, the metric actual, achievement, and the weighted
# composite. Computed on demand — no result rows are stored.
module Kpi
  class ScorecardService
    def self.call(company:, employee:, from:, to:)
      new(company: company, employee: employee, from: from, to: to).call
    end

    def initialize(company:, employee:, from:, to:)
      @company = company
      @employee = employee
      @from = from
      @to = to
    end

    def call
      configs = company.kpi_configs.active.order(:name).select { |config| config.applies_to?(employee) }
      values = metric_values(configs, [ employee.id ])
      rows = configs.map do |config|
        Kpi::Scoring.build_row(config, values.dig(config.metric_key, employee.id) || 0)
      end

      {
        employee: { id: employee.id, name: employee.name },
        from: from.iso8601,
        to: to.iso8601,
        composite_pct: Kpi::Scoring.composite_pct(rows),
        rows: rows
      }
    end

    private

    attr_reader :company, :employee, :from, :to

    def metric_values(configs, employee_ids)
      configs.group_by(&:metric_key).to_h do |metric_key, _metric_configs|
        metric = Kpi::Metrics.find(metric_key)
        [ metric_key, metric.call(company: company, employee_ids: employee_ids, from: from, to: to) ]
      end
    end
  end
end
