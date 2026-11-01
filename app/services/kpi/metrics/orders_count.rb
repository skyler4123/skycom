# frozen_string_literal: true

# Counts paid orders attributed to each salesperson in a date range.
module Kpi
  module Metrics
    class OrdersCount
      def self.key
        "orders_count"
      end

      def self.label
        "Orders sold"
      end

      def self.unit
        "count"
      end

      def self.call(company:, employee_ids:, from:, to:)
        counts = paid_orders(company: company, from: from, to: to)
          .where(salesperson_id: employee_ids)
          .group(:salesperson_id)
          .count

        employee_ids.index_with { |employee_id| counts[employee_id] || 0 }
      end

      def self.paid_orders(company:, from:, to:)
        company.orders.where(
          workflow_status: :paid,
          discarded_at: nil,
          created_at: from..to
        )
      end
    end
  end
end
