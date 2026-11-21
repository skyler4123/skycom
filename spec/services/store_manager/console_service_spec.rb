# frozen_string_literal: true

require "rails_helper"

RSpec.describe StoreManager::ConsoleService, type: :service do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company, timezone: :utc) }
  let(:employee) { create(:employee, company: company, branch: branch, name: "Lekisha Dare") }
  let(:warehouse) { create(:warehouse, company: company, branch: branch, name: "Branch Warehouse") }
  let(:product) { create(:product, company: company, name: "MX Master 3S", code: "LOGI-MX3S") }
  let(:operation) { Seed::OperationService.create(company: company, operation_type: :store_manager) }
  let(:appointment) { operation.branch_operation_appointments.find_by!(branch: branch) }

  it "makes the KPIs agree with the lists under them" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      create_store_invoice_order(
        company: company, branch: branch, employee: employee,
        total_cents: 11_000, tax_cents: 1_000, tender: :cash,
        cash_received_cents: 12_000, change_cents: 1_000
      )
      create_store_invoice_order(
        company: company, branch: branch, employee: employee,
        total_cents: 5_000, tender: :qr
      )
      open = create(:order, company: company, branch: branch, customer: create(:customer, company: company, branch: branch),
        name: "Open Order #{SecureRandom.hex(4)}", workflow_status: :pending,
        fulfillment_channel: :click_collect, created_at: Time.utc(2026, 11, 20, 9, 0, 0))
      open.update_columns(discarded_at: nil)
      create_store_stock(company: company, branch: branch, warehouse: warehouse, product: product,
        quantity: 2, code: "LOGI-MX3S")
      create_store_shift(
        company: company, branch: branch, employee: employee, name: "Morning",
        starts_at: Time.utc(2026, 11, 20, 8, 0, 0), ends_at: Time.utc(2026, 11, 20, 17, 0, 0)
      )

      payload = described_class.call(
        company: company, appointment: appointment,
        now: Time.utc(2026, 11, 20, 10, 0, 0), date: Date.new(2026, 11, 20)
      )

      expect(payload[:kpis]).to include(
        gross_sales_cents: 16_000,
        cashiers_count: 1,
        paid_orders_count: 2,
        orders_to_hand_over: 3,
        shelf_alerts: 1,
        staff_on_duty: 1
      )
      expect(payload[:queue][:counts][:all]).to eq(payload[:kpis][:orders_to_hand_over])
      expect(payload[:cashiers].length).to eq(payload[:kpis][:cashiers_count])
      expect(payload[:shelf][:count]).to eq(payload[:kpis][:shelf_alerts])
      expect(payload[:staff].length).to eq(payload[:kpis][:staff_on_duty])
      expect(payload[:kpis][:gross_sales_delta_pct]).to be_nil
      expect(payload[:queue][:orders].find { |row| row[:id] == open.id }).to include(
        code: open.code, fulfillment_label: "Unfulfilled"
      )
      expect(payload[:footfall]).to include(connected: false, buyers: 2)
    end
  end

  it "uses the same invoice formula for yesterday" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      create_store_invoice_order(
        company: company, branch: branch, total_cents: 10_000,
        created_at: Time.utc(2026, 11, 19, 10, 0, 0)
      )

      payload = described_class.call(
        company: company, appointment: appointment,
        now: Time.utc(2026, 11, 20, 10, 0, 0), date: Date.new(2026, 11, 20)
      )

      expect(payload[:kpis][:previous_gross_sales_cents]).to eq(10_000)
      expect(payload[:kpis][:gross_sales_delta_pct]).to eq(-100.0)
    end
  end
end
