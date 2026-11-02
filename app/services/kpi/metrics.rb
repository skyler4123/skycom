# frozen_string_literal: true

# Kpi::Metrics — registry of computable employee metrics.
#
# Why it exists: KpiConfig stores a metric_key, never code. Adding a metric is
# one class + one registry entry, so the engine stays open without allowing
# companies to run arbitrary SQL.
# How it works: each class exposes key/label/unit and call(company:, employee_ids:,
# from:, to:), returning { employee_id => value }.
module Kpi
  module Metrics
    METRIC_KEYS = %w[orders_count orders_revenue_cents].freeze

    module_function

    def keys
      METRIC_KEYS
    end

    def find(key)
      key = key.to_s
      return nil unless METRIC_KEYS.include?(key)

      "Kpi::Metrics::#{key.camelize}".constantize
    end

    def all
      METRIC_KEYS.map { |key| find(key) }
    end

    def catalog
      all.map { |metric| { key: metric.key, label: metric.label, unit: metric.unit } }
    end
  end
end
