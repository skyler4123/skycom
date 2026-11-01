# frozen_string_literal: true

# Builds the company-wide KPI leaderboard for a date range. Each metric is
# computed once for all employees (grouped query), then configs are applied per
# employee. Also reports paid orders that have no salesperson, so a low score
# caused by missing attribution is visible.
module Kpi
  class LeaderboardService
    def self.call(company:, from:, to:)
      new(company: company, from: from, to: to).call
    end

    def initialize(company:, from:, to:)
      @company = company
      @from = from
      @to = to
    end

    def call
      configs = company.kpi_configs.active.order(:name).to_a
      employees = company.employees.where(discarded_at: nil)
        .includes(:department_employee_appointments, :employee_role_appointments)
        .order(:name).to_a
      values = metric_values(configs, employees.map(&:id))
      rows = employees.map { |employee| employee_row(employee, configs, values) }

      {
        from: from.iso8601,
        to: to.iso8601,
        rows: sort_rows(rows),
        unattributed: unattributed_payload
      }
    end

    private

    attr_reader :company, :from, :to

    def metric_values(configs, employee_ids)
      configs.group_by(&:metric_key).to_h do |metric_key, _metric_configs|
        metric = Kpi::Metrics.find(metric_key)
        [ metric_key, metric.call(company: company, employee_ids: employee_ids, from: from, to: to) ]
      end
    end

    def employee_row(employee, configs, values)
      applicable = configs.select { |config| config.applies_to?(employee) }
      rows = applicable.map do |config|
        Kpi::Scoring.build_row(config, values.dig(config.metric_key, employee.id) || 0)
      end

      {
        employee_id: employee.id,
        name: employee.name,
        composite_pct: Kpi::Scoring.composite_pct(rows),
        rows: rows
      }
    end

    def sort_rows(rows)
      rows.sort_by do |row|
        [ row[:composite_pct].nil? ? 1 : 0, -(row[:composite_pct] || 0), row[:name].to_s ]
      end
    end

    def unattributed_payload
      orders = company.orders.where(
        workflow_status: :paid,
        discarded_at: nil,
        salesperson_id: nil,
        created_at: from..to
      )

      {
        orders_count: orders.count,
        revenue_cents: Analytics::RevenueCalculator.new(company: company, orders: orders).total_cents
      }
    end
  end
end
