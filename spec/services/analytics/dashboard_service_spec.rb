# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analytics::DashboardService do
  subject(:result) { described_class.call(company: company, period: period) }

  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:period) { "this_month" }

  describe "#call" do
    context "with no data" do
      it "returns zero-filled summary" do
        expect(result[:summary]).to include(
          total_revenue_cents: 0,
          total_orders: 0,
          active_customers: 0,
          avg_order_value_cents: 0
        )
        # Owner employee is always active
        expect(result[:summary][:active_employees]).to be >= 1
      end

      it "returns empty arrays for chart data" do
        expect(result[:profit_margins][:by_month]).to eq([])
        expect(result[:inventory_velocity][:by_product]).to eq([])
        expect(result[:staff_performance][:by_employee]).to eq([])
        expect(result[:customer_clv][:by_customer]).to eq([])
      end

      it "returns zero low_stock_count and new_customers" do
        expect(result[:inventory_velocity][:low_stock_count]).to eq(0)
        expect(result[:customer_clv][:new_customers_30d]).to eq(0)
      end
    end

    context "with orders and products" do
      let!(:product) do
        create(:product, company: company, metadata: { "cost_price_cents" => 500 })
      end
      let!(:customer) { create(:customer, company: company, branch: branch) }
      let!(:order) do
        create(:order, company: company, branch: branch, customer: customer,
               workflow_status: :paid)
      end
      let!(:order_appt) do
        OrderAppointment.create!(
          company: company,
          order: order,
          appoint_to: product,
          unit_price: 10.00,
          quantity: 2,
          total_price: 20.00,
          name: "Test appointment"
        )
      end
      let!(:employee) { create(:employee, company: company, branch: branch, lifecycle_status: :active) }

      it "includes revenue in summary" do
        expect(result[:summary][:total_revenue_cents]).to eq(2000)
      end

      it "counts orders" do
        expect(result[:summary][:total_orders]).to eq(1)
      end

      it "counts active customers" do
        expect(result[:summary][:active_customers]).to eq(1)
      end

      it "counts active employees" do
        # 1 owner employee + 1 created = 2
        expect(result[:summary][:active_employees]).to eq(2)
      end

      it "calculates avg order value" do
        expect(result[:summary][:avg_order_value_cents]).to eq(2000)
      end

      it "computes profit margin" do
        # Revenue = 2000 cents, Cost = 500 * 2 = 1000 cents, Margin = (2000-1000)/2000 = 50%
        expect(result[:profit_margins][:overall_margin_pct]).to eq(50.0)
      end

      it "includes monthly profit breakdown" do
        month_data = result[:profit_margins][:by_month].first
        expect(month_data[:revenue_cents]).to eq(2000)
        expect(month_data[:cost_cents]).to eq(1000)
        expect(month_data[:margin_pct]).to eq(50.0)
        expect(month_data[:month]).to eq(Time.current.strftime("%Y-%m"))
      end

      it "includes customer CLV" do
        clv = result[:customer_clv][:by_customer].first
        expect(clv[:total_spent_cents]).to eq(2000)
        expect(clv[:order_count]).to eq(1)
      end
    end

    context "with stock transactions" do
      let!(:product) { create(:product, company: company) }
      let!(:warehouse) { create(:warehouse, company: company) }
      let!(:stock) do
        Stock.create!(company: company, warehouse: warehouse, product: product, quantity: 100)
      end
      let!(:transaction) do
        StockTransaction.create!(
          company: company, product: product,
          warehouse: warehouse,
          category: product.category,
          property_mapping: product.property_mapping,
          direction: :remove, transaction_type: :export, quantity: 10, created_at: 5.days.ago
        )
      end

      it "reports units sold in 30 days" do
        velocity = result[:inventory_velocity][:by_product].first
        expect(velocity[:units_sold_30d]).to eq(10)
        # Stock.quantity starts at 100, after_create callback subtracts 10 → 90
        expect(velocity[:quantity]).to eq(90)
      end
    end

    context "with period filter" do
      let(:period) { "last_month" }

      it "supports last_month" do
        expect(result).to have_key(:summary)
      end

      context "with last_6_months" do
        let(:period) { "last_6_months" }

        it "supports last_6_months" do
          expect(result).to have_key(:profit_margins)
        end
      end

      context "with this_year" do
        let(:period) { "this_year" }

        it "supports this_year" do
          expect(result).to have_key(:summary)
        end
      end
    end
  end
end
