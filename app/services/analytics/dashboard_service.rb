# frozen_string_literal: true

# Analytics::DashboardService — executive analysis payload for one period.
#
# Why it exists: the analytics page is a period-based financial/customer/
# inventory/workforce report, separate from the live health dashboard.
# How it works: delegates revenue math to Analytics::RevenueCalculator, uses
# Analytics::PeriodRange for the current + comparison windows, aggregates
# inventory/customer/cohort data in bounded queries, and returns nil (not a fake
# zero) when a metric has no baseline or no cost data.
module Analytics
  class DashboardService
    TOP_LIMIT = 5
    CLV_LIMIT = 10
    COHORT_MONTHS = 6
    ATTENTION_LIMIT = 5

    def self.call(company:, period: "this_month")
      new(company, period).call
    end

    def initialize(company, period)
      @company = company
      @period_range = Analytics::PeriodRange.new(period)
    end

    def call
      inventory = inventory_velocity_payload
      staff = staff_performance_payload

      {
        period: period_payload,
        summary: summary_payload(inventory, staff),
        profit_margins: profit_margins_payload,
        revenue_mix: revenue_mix_payload,
        top_items: top_items_payload,
        inventory_velocity: inventory,
        staff_performance: staff,
        customer_clv: customer_clv_payload,
        cohorts: cohorts_payload
      }
    end

    private

    attr_reader :company, :period_range

    def current_range
      period_range.current_range
    end

    def previous_range
      period_range.previous_range
    end

    def current_orders
      @current_orders ||= paid_orders_in(current_range)
    end

    def previous_orders
      @previous_orders ||= paid_orders_in(previous_range)
    end

    def paid_orders_in(range)
      company.orders.where(workflow_status: :paid, discarded_at: nil, created_at: range)
    end

    def revenue_calculator
      @revenue_calculator ||= Analytics::RevenueCalculator.new(company: company, orders: current_orders)
    end

    def previous_revenue_calculator
      @previous_revenue_calculator ||= Analytics::RevenueCalculator.new(company: company, orders: previous_orders)
    end

    def period_payload
      {
        key: period_range.key,
        start: current_range.begin,
        end: current_range.end,
        previous_start: previous_range.begin,
        previous_end: previous_range.end
      }
    end

    def summary_payload(inventory, staff)
      current_revenue_cents = revenue_calculator.total_cents
      previous_revenue_cents = previous_revenue_calculator.total_cents
      current_order_count = current_orders.count
      previous_order_count = previous_orders.count
      current_aov = average_order_value(current_revenue_cents, current_order_count)
      previous_aov = average_order_value(previous_revenue_cents, previous_order_count)
      current_customers = active_customer_ids(current_orders)
      previous_customers = active_customer_ids(previous_orders)
      current_margin = revenue_calculator.margin_pct
      previous_margin = previous_revenue_calculator.margin_pct
      total_hours = staff[:totals][:total_hours].to_f

      {
        total_revenue_cents: current_revenue_cents,
        previous_total_revenue_cents: previous_revenue_cents,
        revenue_delta_pct: percentage_change(current_revenue_cents, previous_revenue_cents),
        total_orders: current_order_count,
        previous_total_orders: previous_order_count,
        orders_delta_pct: percentage_change(current_order_count, previous_order_count),
        avg_order_value_cents: current_aov,
        previous_avg_order_value_cents: previous_aov,
        avg_order_value_delta_pct: percentage_change(current_aov, previous_aov),
        active_customers: current_customers.size,
        previous_active_customers: previous_customers.size,
        active_customers_delta_pct: percentage_change(current_customers.size, previous_customers.size),
        new_customers: company.customers.where(created_at: current_range).count,
        gross_profit_cents: revenue_calculator.covered_profit_cents,
        gross_margin_pct: current_margin,
        previous_gross_margin_pct: previous_margin,
        gross_margin_delta_pp: margin_delta(current_margin, previous_margin),
        cost_coverage_pct: revenue_calculator.coverage_pct,
        revenue_per_worked_hour_cents: total_hours.positive? ? (current_revenue_cents / total_hours).round : nil,
        low_stock_count: inventory[:low_stock_count],
        inventory_days_of_cover: inventory[:days_of_cover],
        active_employees: company.employees.where(lifecycle_status: :active).count,
        currency: company.currency
      }
    end

    def profit_margins_payload
      by_month = if revenue_calculator.total_cents.positive?
        data = revenue_calculator.by_month.index_by { |row| row[:month] }
        month_keys(current_range).map do |month|
          data[month] || { month: month, revenue_cents: 0, cost_cents: 0, margin_pct: nil }
        end
      else
        []
      end

      {
        overall_margin_pct: revenue_calculator.margin_pct,
        cost_coverage_pct: revenue_calculator.coverage_pct,
        by_month: by_month
      }
    end

    def revenue_mix_payload
      {
        by_category: revenue_calculator.by_order_category,
        by_branch: revenue_calculator.by_branch
      }
    end

    def top_items_payload
      {
        products: revenue_calculator.top_products(limit: TOP_LIMIT),
        services: revenue_calculator.top_services(limit: TOP_LIMIT)
      }
    end

    def inventory_velocity_payload
      stock_rows = company.stocks.where(discarded_at: nil).includes(:product, :warehouse).to_a
      units_sold = StockTransaction.where(company_id: company.id, direction: :remove)
        .where(created_at: current_range)
        .group(:product_id)
        .sum(:quantity)
      period_days = [ (current_range.end.to_date - current_range.begin.to_date + 1), 1 ].max
      revenue_by_product = revenue_calculator.product_totals.index_by { |row| row[:product_id] }

      by_product = stock_rows.group_by(&:product_id).map do |product_id, rows|
        quantity = rows.sum(&:quantity)
        pending = rows.sum(&:pending)
        available = quantity - pending
        sold = units_sold[product_id].to_i
        daily_units = sold.to_f / period_days
        days_of_cover = daily_units.positive? ? (available / daily_units).round(1) : nil
        revenue_row = revenue_by_product[product_id]

        {
          product_id: product_id,
          name: rows.first.product&.name,
          quantity: quantity,
          pending: pending,
          available: available,
          units_sold: sold,
          turnover_rate: quantity.positive? ? (sold.to_f / quantity).round(2) : 0.0,
          days_of_cover: days_of_cover,
          revenue_cents: revenue_row&.dig(:revenue_cents) || 0,
          cost_cents: revenue_row&.dig(:cost_cents),
          margin_pct: revenue_row&.dig(:margin_pct)
        }
      end.sort_by { |row| [ -row[:units_sold], row[:name].to_s ] }

      low_stock_rows = stock_rows
        .select { |row| row.quantity - row.pending < LOW_STOCK_THRESHOLD }
        .sort_by { |row| row.quantity - row.pending }

      {
        low_stock_count: low_stock_rows.size,
        low_stock_items: low_stock_rows.first(ATTENTION_LIMIT).map do |stock|
          {
            stock_id: stock.id,
            product_id: stock.product_id,
            product_name: stock.product&.name,
            warehouse_name: stock.warehouse&.name,
            quantity: stock.quantity,
            pending: stock.pending,
            available: stock.quantity - stock.pending
          }
        end,
        stock_value_cost_cents: stock_value_cost_cents(stock_rows),
        stock_value_retail_cents: stock_rows.sum { |row| row.product&.price_cents.to_i * row.quantity },
        days_of_cover: weighted_days_of_cover(by_product),
        by_product: by_product
      }
    end

    def staff_performance_payload
      records = company.attendance_months.where(month: current_range).includes(:employee)

      by_employee = records.map do |attendance|
        total_days = attendance.total_present_days + attendance.total_absent_days
        rate = total_days.positive? ? (attendance.total_present_days * 100.0 / total_days).round(1) : 0.0

        {
          employee_id: attendance.employee_id,
          name: attendance.employee&.name,
          total_hours: (attendance.total_work_minutes / 60.0).round(1),
          overtime_hours: (attendance.total_overtime_minutes / 60.0).round(1),
          absent_days: attendance.total_absent_days,
          attendance_rate: rate
        }
      end.sort_by { |row| -row[:total_hours] }

      average_rate = if by_employee.any?
        (by_employee.sum { |row| row[:attendance_rate] } / by_employee.size).round(1)
      end

      {
        by_employee: by_employee,
        totals: {
          employees_count: by_employee.size,
          total_hours: by_employee.sum { |row| row[:total_hours] }.round(1),
          overtime_hours: by_employee.sum { |row| row[:overtime_hours] }.round(1),
          absent_days: by_employee.sum { |row| row[:absent_days] },
          average_attendance_rate: average_rate
        }
      }
    end

    def customer_clv_payload
      paid_orders = company.orders.where(workflow_status: :paid, discarded_at: nil).where.not(customer_id: nil)
      order_customers = paid_orders.pluck(:id, :customer_id).to_h
      order_totals = Analytics::RevenueCalculator.new(company: company, orders: paid_orders).order_totals
      rows = Hash.new { |hash, key| hash[key] = { total_spent_cents: 0, order_count: 0 } }

      order_totals.each do |order_id, cents|
        customer_id = order_customers[order_id]
        next if customer_id.nil?

        rows[customer_id][:total_spent_cents] += cents
        rows[customer_id][:order_count] += 1
      end

      names = company.customers.where(id: rows.keys).pluck(:id, :name).to_h
      by_customer = rows.map do |customer_id, data|
        {
          customer_id: customer_id,
          name: names[customer_id],
          total_spent_cents: data[:total_spent_cents],
          order_count: data[:order_count],
          avg_order_value_cents: average_order_value(data[:total_spent_cents], data[:order_count])
        }
      end.sort_by { |row| -row[:total_spent_cents] }.first(CLV_LIMIT)

      {
        by_customer: by_customer,
        new_customers: company.customers.where(created_at: current_range).count,
        repeat_customer_rate: repeat_customer_rate
      }
    end

    def cohorts_payload
      paid_orders = company.orders.where(workflow_status: :paid, discarded_at: nil).where.not(customer_id: nil)
      first_orders = paid_orders.group(:customer_id).minimum(:created_at)
      return [] if first_orders.empty?

      first_months = first_orders.transform_values { |time| time.strftime("%Y-%m") }
      paid_months = paid_orders.pluck(:customer_id, :created_at).group_by(&:first).transform_values do |rows|
        rows.map { |_, time| time.strftime("%Y-%m") }.uniq
      end

      current_month = current_range.end.to_date.beginning_of_month
      cohort_start = current_month - (COHORT_MONTHS - 1).months
      cohorts = []
      cursor = cohort_start

      while cursor <= current_month
        key = cursor.strftime("%Y-%m")
        customer_ids = first_months.select { |_, month| month == key }.keys

        if customer_ids.any?
          retention = (0...COHORT_MONTHS).map do |offset|
            month_date = cursor + offset.months
            next nil if month_date > current_range.end.to_date
            next 100.0 if offset.zero?

            retained = customer_ids.count { |id| paid_months[id]&.include?(month_date.strftime("%Y-%m")) }
            (retained * 100.0 / customer_ids.size).round(1)
          end

          cohorts << { cohort: key, new_customers: customer_ids.size, retention: retention }
        end

        cursor = cursor.next_month
      end

      cohorts
    end

    def active_customer_ids(orders)
      orders.where.not(customer_id: nil).distinct.pluck(:customer_id)
    end

    def repeat_customer_rate
      current_customer_ids = active_customer_ids(current_orders)
      return 0.0 if current_customer_ids.empty?

      returning_customer_ids = company.orders
        .where(workflow_status: :paid, discarded_at: nil)
        .where("created_at < ?", current_range.begin)
        .where(customer_id: current_customer_ids)
        .distinct
        .pluck(:customer_id)

      (returning_customer_ids.size * 100.0 / current_customer_ids.size).round(1)
    end

    def weighted_days_of_cover(rows)
      rows_with_cover = rows.select { |row| row[:days_of_cover] && row[:units_sold].positive? }
      return nil if rows_with_cover.empty?

      total_sold = rows_with_cover.sum { |row| row[:units_sold] }
      return nil if total_sold.zero?

      (rows_with_cover.sum { |row| row[:days_of_cover] * row[:units_sold] } / total_sold).round(1)
    end

    def stock_value_cost_cents(stock_rows)
      stock_rows.sum do |row|
        cost = product_cost_cents(row.product)
        cost.nil? ? 0 : cost * row.quantity
      end
    end

    def product_cost_cents(product)
      metadata = product&.metadata
      raw = metadata.is_a?(Hash) ? metadata : {}
      cost = raw.key?("cost_price_cents") ? raw["cost_price_cents"] : raw[:cost_price_cents]
      cost.nil? ? nil : cost.to_i
    end

    def month_keys(range)
      cursor = range.begin.to_date.beginning_of_month
      finish = range.end.to_date.beginning_of_month
      keys = []

      while cursor <= finish
        keys << cursor.strftime("%Y-%m")
        cursor = cursor.next_month
      end

      keys
    end

    def average_order_value(total_cents, order_count)
      order_count.positive? ? (total_cents.to_f / order_count).round : 0
    end

    def percentage_change(current_value, previous_value)
      return nil if previous_value.to_f.zero?

      (((current_value.to_f - previous_value.to_f) / previous_value.to_f) * 100).round(1)
    end

    def margin_delta(current_margin, previous_margin)
      return nil if current_margin.nil? || previous_margin.nil?

      (current_margin - previous_margin).round(1)
    end
  end
end
