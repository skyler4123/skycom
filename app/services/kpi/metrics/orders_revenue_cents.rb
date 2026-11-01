# frozen_string_literal: true

# Sums paid order revenue per salesperson, in minor units. Delegates the
# line-item math to Analytics::RevenueCalculator so KPI revenue cannot drift
# from the dashboard.
module Kpi
  module Metrics
    class OrdersRevenueCents
      def self.key
        "orders_revenue_cents"
      end

      def self.label
        "Sales revenue"
      end

      def self.unit
        "currency_cents"
      end

      def self.call(company:, employee_ids:, from:, to:)
        orders = Kpi::Metrics::OrdersCount.paid_orders(company: company, from: from, to: to)
          .where(salesperson_id: employee_ids)
        totals = Analytics::RevenueCalculator.new(company: company, orders: orders).order_totals
        salespeople = orders.pluck(:id, :salesperson_id).to_h
        result = employee_ids.index_with { 0 }

        totals.each do |order_id, cents|
          salesperson_id = salespeople[order_id]
          result[salesperson_id] += cents if result.key?(salesperson_id)
        end

        result
      end
    end
  end
end
