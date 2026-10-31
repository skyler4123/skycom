# frozen_string_literal: true

# Dashboards::OverviewService — builds the company-health dashboard payload.
#
# Why it exists: the dashboard is an operations + exception surface, not a
# second analytics report. It reads current-month sales health, live alerts,
# today's staff pulse, upcoming events and the company wallet in one payload.
# How it works: financial sections are only computed when the caller can read
# invoices (owner/admin/manager); everyone else gets the operational shell.
# Revenue math is delegated to Analytics::RevenueCalculator so the dashboard
# and analytics page cannot drift.
module Dashboards
  class OverviewService
    TREND_DAYS = 30
    ATTENTION_LIMIT = 5
    RECENT_ORDERS_LIMIT = 5
    TOP_CUSTOMERS_LIMIT = 5
    UPCOMING_EVENTS_LIMIT = 5

    def self.call(company:, can_view_financials:)
      new(company: company, can_view_financials: can_view_financials).call
    end

    def initialize(company:, can_view_financials:)
      @company = company
      @can_view_financials = can_view_financials
    end

    def call
      payload = {
        period: period_payload,
        company: company_payload,
        permissions: { can_view_financials: can_view_financials },
        kpis: operational_kpis,
        attention: attention_payload,
        recent_orders: recent_orders_payload,
        staff_today: staff_today_payload,
        upcoming_events: upcoming_events_payload
      }

      return payload unless can_view_financials

      payload[:kpis] = operational_kpis.merge(financial_kpis)
      payload[:trend] = trend_payload
      payload[:revenue_mix] = revenue_calculator.by_order_category
      payload[:top_customers] = top_customers_payload
      payload[:wallet] = wallet_payload
      payload
    end

    private

    attr_reader :company, :can_view_financials

    def period_range
      @period_range ||= Analytics::PeriodRange.new("this_month")
    end

    def current_range
      period_range.current_range
    end

    def previous_range
      period_range.previous_range
    end

    def current_orders
      @current_orders ||= company.orders.where(workflow_status: :paid, discarded_at: nil, created_at: current_range)
    end

    def previous_orders
      @previous_orders ||= company.orders.where(workflow_status: :paid, discarded_at: nil, created_at: previous_range)
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
        end: current_range.end
      }
    end

    def company_payload
      company.as_json(only: %i[
        id name description code business_type ownership_type
        currency timezone lifecycle_status workflow_status
        registration_number vat_id tax_id email phone_number website
        address_line_1 city postal_code country employee_count
        fiscal_year_end_month created_at
      ]).except("resource_names").merge(
        owner: company.user&.as_json(only: %i[id email first_name last_name]),
        branches_count: company.branches.count,
        active_employees_count: company.employees.where(lifecycle_status: :active).count
      )
    end

    def operational_kpis
      {
        orders_count: current_orders.count,
        orders_delta_pct: percentage_change(current_orders.count, previous_orders.count),
        active_customers_count: active_customer_ids.size,
        new_customers_count: company.customers.where(created_at: current_range).count,
        low_stock_count: low_stock_scope.count,
        pending_approvals_count: approvals_payload[:total],
        staff_present_count: staff_today_payload[:present] + staff_today_payload[:half_day] + staff_today_payload[:late],
        staff_scheduled_count: staff_today_payload[:scheduled],
        urgent_tickets_count: urgent_tickets_scope.count
      }
    end

    def financial_kpis
      current_aov = average_order_value(revenue_calculator.total_cents, current_orders.count)
      previous_aov = average_order_value(previous_revenue_calculator.total_cents, previous_orders.count)

      {
        revenue_cents: revenue_calculator.total_cents,
        revenue_delta_pct: percentage_change(revenue_calculator.total_cents, previous_revenue_calculator.total_cents),
        avg_order_value_cents: current_aov,
        avg_order_value_delta_pct: percentage_change(current_aov, previous_aov),
        gross_margin_pct: revenue_calculator.margin_pct,
        cost_coverage_pct: revenue_calculator.coverage_pct,
        credits_total: wallet&.total_credit_balance || 0,
        credits_debt: wallet&.debt_credit_balance || 0
      }
    end

    def trend_payload
      daily_revenue = revenue_calculator.by_day
      daily_orders = current_orders.group("DATE(orders.created_at)").count.transform_keys do |key|
        key.is_a?(String) ? Date.parse(key) : key.to_date
      end

      ((Date.current - (TREND_DAYS - 1))..Date.current).map do |date|
        {
          date: date.iso8601,
          revenue_cents: daily_revenue[date] || 0,
          orders_count: daily_orders[date] || 0
        }
      end
    end

    def attention_payload
      {
        low_stock: low_stock_payload,
        approvals: approvals_payload,
        overdue_invoices: can_view_financials ? overdue_invoices_payload : [],
        urgent_tickets: urgent_tickets_payload
      }
    end

    def low_stock_scope
      company.stocks.where(discarded_at: nil).where("quantity - pending < ?", LOW_STOCK_THRESHOLD)
    end

    def low_stock_payload
      low_stock_scope
        .includes(:product, :warehouse)
        .order(Arel.sql("(quantity - pending) ASC"))
        .limit(ATTENTION_LIMIT)
        .map do |stock|
          {
            stock_id: stock.id,
            product_id: stock.product_id,
            product_name: stock.product&.name,
            warehouse_name: stock.warehouse&.name,
            quantity: stock.quantity,
            pending: stock.pending,
            available: stock.quantity - stock.pending
          }
        end
    end

    def approvals_payload
      @approvals_payload ||= begin
        purchases = company.purchases.where(workflow_status: :pending, discarded_at: nil).count
        tickets = company.tickets.where(workflow_status: :pending, discarded_at: nil).count
        attendance_requests = company.attendance_requests.where(status: :pending, discarded_at: nil).count

        {
          purchases: purchases,
          tickets: tickets,
          attendance_requests: attendance_requests,
          total: purchases + tickets + attendance_requests
        }
      end
    end

    def overdue_invoices_payload
      company.invoices
        .where(payment_status: :unpaid, discarded_at: nil)
        .where.not(due_date: nil)
        .where("due_date < ?", Time.current)
        .order(:due_date)
        .limit(ATTENTION_LIMIT)
        .map do |invoice|
          {
            id: invoice.id,
            name: invoice.name,
            code: invoice.code,
            price_cents: invoice.price_cents,
            due_date: invoice.due_date
          }
        end
    end

    def urgent_tickets_scope
      company.tickets
        .where(discarded_at: nil, priority: %i[high urgent])
        .where.not(workflow_status: %i[completed cancelled])
    end

    def urgent_tickets_payload
      urgent_tickets_scope.order(priority: :desc, created_at: :desc).limit(ATTENTION_LIMIT).map do |ticket|
        {
          id: ticket.id,
          name: ticket.name,
          priority: ticket.priority,
          assigned_to: ticket.assigned_employee&.name
        }
      end
    end

    def recent_orders_payload
      orders = company.orders.where(discarded_at: nil)
        .order(created_at: :desc)
        .limit(RECENT_ORDERS_LIMIT)
        .includes(:customer, :branch)
      totals = can_view_financials ? Analytics::RevenueCalculator.new(company: company, orders: orders).order_totals : {}

      orders.map do |order|
        {
          id: order.id,
          code: order.code,
          name: order.name,
          customer_name: order.customer&.name || order.name,
          branch_name: order.branch&.name,
          workflow_status: order.workflow_status,
          total_cents: totals[order.id],
          created_at: order.created_at
        }
      end
    end

    def top_customers_payload
      order_customer_ids = current_orders.pluck(:id, :customer_id).to_h
      rows = Hash.new { |hash, key| hash[key] = { total_spent_cents: 0, order_count: 0 } }

      revenue_calculator.order_totals.each do |order_id, cents|
        customer_id = order_customer_ids[order_id]
        next if customer_id.nil?

        rows[customer_id][:total_spent_cents] += cents
        rows[customer_id][:order_count] += 1
      end

      names = company.customers.where(id: rows.keys).pluck(:id, :name).to_h
      rows.map do |customer_id, data|
        {
          customer_id: customer_id,
          name: names[customer_id],
          total_spent_cents: data[:total_spent_cents],
          order_count: data[:order_count]
        }
      end.sort_by { |row| -row[:total_spent_cents] }.first(TOP_CUSTOMERS_LIMIT)
    end

    def staff_today_payload
      @staff_today_payload ||= begin
        counts = company.attendance_days
          .where(attendance_date: Date.current, discarded_at: nil)
          .group(:attendance_status)
          .count

        present = counts["present"].to_i
        half_day = counts["half_day"].to_i
        late = counts["late"].to_i
        absent = counts["absent"].to_i
        missing_checkout = counts["missing_checkout"].to_i
        recorded = present + half_day + late + absent + missing_checkout
        rate = recorded.zero? ? nil : ((present + half_day + late) * 100.0 / recorded).round(1)

        {
          scheduled: company.scheduled_shifts.where(work_date: Date.current, discarded_at: nil).count,
          present: present,
          half_day: half_day,
          late: late,
          absent: absent,
          missing_checkout: missing_checkout,
          attendance_rate: rate
        }
      end
    end

    def upcoming_events_payload
      company.events
        .where(discarded_at: nil)
        .where("end_at >= ?", Time.current)
        .order(:start_at)
        .limit(UPCOMING_EVENTS_LIMIT)
        .includes(:branch)
        .map do |event|
          {
            id: event.id,
            name: event.name,
            start_at: event.start_at,
            end_at: event.end_at,
            branch_name: event.branch&.name
          }
        end
    end

    def wallet_payload
      {
        main_credit_balance: wallet&.main_credit_balance || 0,
        promo_credit_balance: wallet&.promo_credit_balance || 0,
        debt_credit_balance: wallet&.debt_credit_balance || 0,
        total_credit_balance: wallet&.total_credit_balance || 0,
        used_this_month: company.company_wallet_logs
          .where(change_type: :debit, created_at: current_range)
          .sum(:change_amount)
          .abs,
        currency: company.currency,
        access_cost: CREDIT_USAGE_RATES[:access_dashboard]
      }
    end

    def wallet
      @wallet ||= company.company_wallet
    end

    def active_customer_ids
      @active_customer_ids ||= current_orders.where.not(customer_id: nil).distinct.pluck(:customer_id)
    end

    def average_order_value(total_cents, order_count)
      order_count.positive? ? (total_cents.to_f / order_count).round : 0
    end

    def percentage_change(current_value, previous_value)
      return nil if previous_value.to_f.zero?

      (((current_value.to_f - previous_value.to_f) / previous_value.to_f) * 100).round(1)
    end
  end
end
