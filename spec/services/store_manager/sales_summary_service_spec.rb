# frozen_string_literal: true

require "rails_helper"

RSpec.describe StoreManager::SalesSummaryService, type: :service do
  let(:company) { create(:company, currency: :usd) }
  let(:branch) { create(:branch, company: company, timezone: :utc) }
  let(:employee) { create(:employee, company: company, branch: branch, name: "Marcus Sterling") }

  it "uses invoice totals, not line-item subtotals, and splits tenders" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      create_store_invoice_order(
        company: company, branch: branch, employee: employee,
        total_cents: 11_000, tax_cents: 1_000, tender: :cash,
        cash_received_cents: 12_000, change_cents: 1_000
      )
      create_store_invoice_order(
        company: company, branch: branch, employee: employee,
        total_cents: 5_000, tax_cents: 0, tender: :qr
      )

      summary = described_class.call(company: company, branch: branch, date: Date.new(2026, 11, 20))

      expect(summary[:gross_sales_cents]).to eq(16_000)
      expect(summary[:orders_count]).to eq(2)
      expect(summary[:tax_cents]).to eq(1_000)
      expect(summary[:cash_sales_cents]).to eq(11_000)
      expect(summary[:qr_sales_cents]).to eq(5_000)
      expect(summary[:cash_received_cents]).to eq(12_000)
      expect(summary[:change_cents]).to eq(1_000)
      expect(summary[:cashiers].first).to include(name: "Marcus Sterling", sales_cents: 16_000, orders_count: 2)
    end
  end

  it "ignores cancelled orders and another day's invoices" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      create_store_invoice_order(company: company, branch: branch, total_cents: 10_000)
      create_store_invoice_order(company: company, branch: branch, total_cents: 7_000, workflow_status: :cancelled)
      create_store_invoice_order(
        company: company, branch: branch, total_cents: 3_000,
        created_at: Time.utc(2026, 11, 19, 10, 0, 0)
      )

      summary = described_class.call(company: company, branch: branch, date: Date.new(2026, 11, 20))

      expect(summary[:gross_sales_cents]).to eq(10_000)
      expect(summary[:orders_count]).to eq(1)
    end
  end
end
