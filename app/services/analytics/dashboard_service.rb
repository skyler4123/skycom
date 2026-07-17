module Analytics
  class DashboardService
    def self.call(company:, period: "this_month")
      new(company, period).call
    end

    def initialize(company, period)
      @company = company
      @period = period
      @date_range = compute_date_range
    end

    def call
      {
        summary: compute_summary,
        profit_margins: compute_profit_margins,
        inventory_velocity: compute_inventory_velocity,
        staff_performance: compute_staff_performance,
        customer_clv: compute_customer_clv
      }
    end

    private

    attr_reader :company, :period, :date_range

    def compute_date_range
      case period
      when "last_month" then 1.month.ago.beginning_of_month..1.month.ago.end_of_month
      when "last_6_months" then 6.months.ago.beginning_of_month..Time.current
      when "this_year" then Time.current.beginning_of_year..Time.current
      else Time.current.beginning_of_month..Time.current
      end
    end

    def currency_code
      code = CURRENCIE_CODES.key(company.currency_code) || :usd
      code.to_s.upcase
    end

    def compute_summary
      orders = company.orders.where(workflow_status: :paid, created_at: date_range)
      revenue = compute_revenue(orders)

      {
        total_revenue_cents: revenue,
        total_orders: orders.count,
        active_customers: company.customers.count,
        active_employees: company.employees.where(lifecycle_status: :active).count,
        avg_order_value_cents: orders.count.positive? ? (revenue / orders.count).to_i : 0,
        currency: currency_code
      }
    end

    def compute_revenue(orders)
      revenue_cents = 0
      OrderAppointment.where(order_id: orders.select(:id)).find_each do |oa|
        next unless oa.total_price
        revenue_cents += (oa.total_price * 100).to_i
      end
      revenue_cents
    end

    def compute_profit_margins
      orders = company.orders.where(workflow_status: :paid, created_at: date_range)

      monthly_data = {}
      total_revenue = 0
      total_cost = 0

      OrderAppointment.where(order_id: orders.select(:id))
        .includes(:appoint_to)
        .find_each do |oa|
        next unless oa.total_price

        month = oa.created_at.strftime("%Y-%m")
        monthly_data[month] ||= { revenue_cents: 0, cost_cents: 0 }

        revenue = (oa.total_price * 100).to_i
        monthly_data[month][:revenue_cents] += revenue
        total_revenue += revenue

        if oa.appoint_to.respond_to?(:metadata)
          raw = oa.appoint_to.read_attribute_before_type_cast(:metadata)
          meta = raw.is_a?(::String) ? (JSON.parse(raw) rescue nil) : raw
          cost_price = meta.is_a?(Hash) ? (meta["cost_price_cents"] || 0).to_i : Array(meta).first.to_i
          cost = cost_price * (oa.quantity || 1)
          monthly_data[month][:cost_cents] += cost
          total_cost += cost
        end
      end

      by_month = monthly_data.sort.map do |month, data|
        margin = data[:revenue_cents].positive? ? ((data[:revenue_cents] - data[:cost_cents]) * 100.0 / data[:revenue_cents]).round(1) : 0.0
        data.merge(month: month, margin_pct: margin)
      end

      overall = total_revenue.positive? ? ((total_revenue - total_cost) * 100.0 / total_revenue).round(1) : 0.0

      { overall_margin_pct: overall, by_month: by_month }
    end

    def compute_inventory_velocity
      thirty_days_ago = 30.days.ago

      units_sold = StockTransaction.where(company_id: company.id)
                                     .where(direction: :remove)
                                     .where("created_at >= ?", thirty_days_ago)
                                     .group(:product_id)
                                     .sum(:quantity)

      by_product = company.stocks.includes(:product).map do |stock|
        sold = units_sold[stock.product_id] || 0
        turnover = stock.quantity.positive? ? (sold.to_f / stock.quantity).round(2) : 0.0
        {
          product_id: stock.product_id,
          name: stock.product&.name || "Unknown",
          quantity: stock.quantity,
          units_sold_30d: sold,
          turnover_rate: turnover
        }
      end

      low_stock_count = by_product.count { |p| p[:quantity] < 10 }

      { low_stock_count: low_stock_count, by_product: by_product }
    end

    def compute_staff_performance
      attendance_records = company.attendance_months
                                   .where(month: date_range)
                                   .includes(:employee)

      by_employee = attendance_records.map do |am|
        total_days = am.total_present_days + am.total_absent_days
        rate = total_days.positive? ? (am.total_present_days * 100.0 / total_days).round(1) : 0.0
        {
          employee_id: am.employee_id,
          name: am.employee&.name || "Unknown",
          total_hours: (am.total_work_minutes / 60.0).round(1),
          overtime_hours: (am.total_overtime_minutes / 60.0).round(1),
          absent_days: am.total_absent_days,
          attendance_rate: rate
        }
      end

      { by_employee: by_employee }
    end

    def compute_customer_clv
      thirty_days_ago = 30.days.ago

      by_customer = company.customers.map do |customer|
        paid_orders = customer.orders.where(workflow_status: :paid)
        count = paid_orders.count

        spent = 0
        if count.positive?
          OrderAppointment.where(order_id: paid_orders.select(:id)).find_each do |oa|
            spent += (oa.total_price * 100).to_i if oa.total_price
          end
        end

        {
          customer_id: customer.id,
          name: customer.name,
          total_spent_cents: spent,
          order_count: count,
          avg_order_value_cents: count.positive? ? (spent / count).to_i : 0
        }
      end.sort_by { |c| -c[:total_spent_cents] }

      new_customers = company.customers.where("created_at >= ?", thirty_days_ago).count

      { by_customer: by_customer, new_customers_30d: new_customers }
    end
  end
end
