# frozen_string_literal: true

# Analytics::RevenueCalculator — reads every order line-item type once and
# exposes the revenue/cost aggregates used by both dashboards.
#
# Why it exists: order totals are derived from five atomic appointment tables;
# duplicating the math in two services drifts. Cost is only known for product
# lines whose product metadata carries cost_price_cents, so margin is reported
# on the covered revenue slice and coverage_pct tells the UI how complete it is.
# How it works: loads order metadata and line rows in bulk (no per-order
# queries), converts major-unit line totals to minor units currency-aware
# (USD × 100, VND × 1), and memoizes the aggregates.
module Analytics
  class RevenueCalculator
    LINE_ITEM_TYPES = [
      { model: OrderProductAppointment, type: :product, item_key: :product_id },
      { model: OrderServiceAppointment, type: :service, item_key: :service_id },
      { model: OrderProductGroupAppointment, type: :product_group, item_key: :product_group_id },
      { model: OrderServiceGroupAppointment, type: :service_group, item_key: :service_group_id },
      { model: OrderSubscriptionPlanAppointment, type: :subscription, item_key: :subscription_plan_id }
    ].freeze

    def initialize(company:, orders:)
      @company = company
      @orders = orders
    end

    def total_cents
      line_items.sum { |item| amount_to_cents(item[:total_price]) }
    end

    def product_revenue_cents
      product_lines.sum { |item| amount_to_cents(item[:total_price]) }
    end

    def covered_revenue_cents
      covered_product_lines.sum { |item| amount_to_cents(item[:total_price]) }
    end

    def covered_cost_cents
      covered_product_lines.sum { |item| product_cost_cents(item[:item_id]).to_i * item[:quantity].to_i }
    end

    def covered_profit_cents
      covered_revenue_cents - covered_cost_cents
    end

    def margin_pct
      return nil if covered_revenue_cents.zero?

      ((covered_profit_cents * 100.0) / covered_revenue_cents).round(1)
    end

    def coverage_pct
      return nil if total_cents.zero?

      ((covered_revenue_cents * 100.0) / total_cents).round(1)
    end

    def order_totals
      @order_totals ||= line_items.group_by { |item| item[:order_id] }
        .transform_values { |items| items.sum { |item| amount_to_cents(item[:total_price]) } }
    end

    def by_day
      @by_day ||= order_totals.each_with_object(Hash.new(0)) do |(order_id, cents), result|
        result[order_meta[order_id][:created_at].to_date] += cents
      end
    end

    def by_month
      @by_month ||= begin
        months = Hash.new { |hash, key| hash[key] = { revenue_cents: 0, cost_cents: 0, covered_revenue_cents: 0 } }

        line_items.each do |item|
          month = order_meta[item[:order_id]][:created_at].strftime("%Y-%m")
          months[month][:revenue_cents] += amount_to_cents(item[:total_price])
        end

        covered_product_lines.each do |item|
          month = order_meta[item[:order_id]][:created_at].strftime("%Y-%m")
          months[month][:covered_revenue_cents] += amount_to_cents(item[:total_price])
          months[month][:cost_cents] += product_cost_cents(item[:item_id]).to_i * item[:quantity].to_i
        end

        months.sort.map do |month, data|
          covered_revenue = data[:covered_revenue_cents]
          margin = if covered_revenue.positive?
            (((covered_revenue - data[:cost_cents]) * 100.0) / covered_revenue).round(1)
          end

          {
            month: month,
            revenue_cents: data[:revenue_cents],
            cost_cents: data[:cost_cents],
            margin_pct: margin
          }
        end
      end
    end

    def by_order_category
      @by_order_category ||= grouped_totals(:category_id, Category)
    end

    def by_branch
      @by_branch ||= grouped_totals(:branch_id, Branch)
    end

    def product_totals
      @product_totals ||= begin
        rows = product_lines.group_by { |item| item[:item_id] }.map do |product_id, items|
          revenue_cents = items.sum { |item| amount_to_cents(item[:total_price]) }
          quantity = items.sum { |item| item[:quantity].to_i }
          unit_cost = product_cost_cents(product_id)
          cost_cents = unit_cost.nil? ? nil : unit_cost * quantity
          margin = if cost_cents.nil? || revenue_cents.zero?
            nil
          else
            (((revenue_cents - cost_cents) * 100.0) / revenue_cents).round(1)
          end

          {
            product_id: product_id,
            name: product_names[product_id],
            quantity: quantity,
            revenue_cents: revenue_cents,
            cost_cents: cost_cents,
            margin_pct: margin
          }
        end

        rows.sort_by { |row| -row[:revenue_cents] }
      end
    end

    def service_totals
      @service_totals ||= begin
        rows = service_lines.group_by { |item| item[:item_id] }.map do |service_id, items|
          {
            service_id: service_id,
            name: service_names[service_id],
            quantity: items.sum { |item| item[:quantity].to_i },
            revenue_cents: items.sum { |item| amount_to_cents(item[:total_price]) }
          }
        end

        rows.sort_by { |row| -row[:revenue_cents] }
      end
    end

    def top_products(limit: 5)
      product_totals.first(limit)
    end

    def top_services(limit: 5)
      service_totals.first(limit)
    end

    private

    def line_items
      @line_items ||= LINE_ITEM_TYPES.flat_map do |config|
        config[:model]
          .where(company_id: @company.id, order_id: order_ids, discarded_at: nil)
          .pluck(:order_id, config[:item_key], :quantity, :total_price)
          .map do |order_id, item_id, quantity, total_price|
            {
              type: config[:type],
              order_id: order_id,
              item_id: item_id,
              quantity: quantity.to_i,
              total_price: total_price
            }
          end
      end
    end

    def product_lines
      @product_lines ||= line_items.select { |item| item[:type] == :product }
    end

    def service_lines
      @service_lines ||= line_items.select { |item| item[:type] == :service }
    end

    def covered_product_lines
      @covered_product_lines ||= product_lines.select { |item| !product_cost_cents(item[:item_id]).nil? }
    end

    def order_meta
      @order_meta ||= @orders.pluck(:id, :created_at, :category_id, :branch_id).to_h do |id, created_at, category_id, branch_id|
        [ id, { created_at: created_at, category_id: category_id, branch_id: branch_id } ]
      end
    end

    def order_ids
      @order_ids ||= order_meta.keys
    end

    def grouped_totals(foreign_key, model)
      totals = order_totals.each_with_object(Hash.new(0)) do |(order_id, cents), result|
        result[order_meta[order_id][foreign_key]] += cents
      end
      names = model.where(company_id: @company.id, id: totals.keys.compact).pluck(:id, :name).to_h
      grand_total = totals.values.sum

      totals.map do |id, cents|
        {
          id: id,
          name: names[id],
          revenue_cents: cents,
          pct: grand_total.zero? ? 0.0 : ((cents * 100.0) / grand_total).round(1)
        }
      end.sort_by { |row| -row[:revenue_cents] }
    end

    def product_ids
      @product_ids ||= product_lines.map { |item| item[:item_id] }.uniq
    end

    def service_ids
      @service_ids ||= service_lines.map { |item| item[:item_id] }.uniq
    end

    def product_names
      @product_names ||= Product.where(company_id: @company.id, id: product_ids).pluck(:id, :name).to_h
    end

    def service_names
      @service_names ||= Service.where(company_id: @company.id, id: service_ids).pluck(:id, :name).to_h
    end

    def product_costs
      @product_costs ||= Product.where(company_id: @company.id, id: product_ids).pluck(:id, :metadata).to_h do |id, metadata|
        raw = metadata.is_a?(Hash) ? metadata : {}
        cost = raw.key?("cost_price_cents") ? raw["cost_price_cents"] : raw[:cost_price_cents]
        [ id, cost.nil? ? nil : cost.to_i ]
      end
    end

    def product_cost_cents(product_id)
      product_costs[product_id]
    end

    def amount_to_cents(value)
      return 0 if value.nil?

      amount = value.to_d
      company_currency == "vnd" ? amount.round.to_i : (amount * 100).round.to_i
    end

    def company_currency
      @company_currency ||= @company.currency.to_s
    end
  end
end
