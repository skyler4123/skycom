# frozen_string_literal: true

require "rails_helper"

RSpec.describe Inventory::ConsoleService do
  let(:company) { create(:company, business_type: :retail) }
  let(:branch) { create(:branch, company: company) }
  let(:warehouse) { create(:warehouse, company: company, branch: branch) }
  let(:other_warehouse) { create(:warehouse, company: company, branch: branch) }
  let(:operation) { create(:operation, company: company, operation_type: :inventory) }
  let(:appointment) { create(:operation_warehouse_appointment, company: company, operation: operation, warehouse: warehouse) }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "stocks") }

  def create_stock(code:, name:, quantity:, pending:, location: nil, warehouse: nil)
    product = create(:product, company: company, name: name, price_cents: 900)
    Stock.create!(company: company, warehouse: warehouse || self.warehouse, branch: branch, product: product,
      category: category, property_mapping: category.default_property_mapping,
      name: name, code: code, quantity: quantity, pending: pending, property_string_1: location)
  end

  def create_document(base, code:, quantity:, status:, hours_ago:, warehouse: nil)
    product = create(:product, company: company)
    record = Seed::StockImportService.create(company: company, branch: branch,
      warehouse: warehouse || self.warehouse, product: product, code: code, quantity: quantity,
      workflow_status: status) if base == StockImport
    record = Seed::StockExportService.create(company: company, branch: branch,
      warehouse: warehouse || self.warehouse, product: product, code: code, quantity: quantity,
      workflow_status: status) if base == StockExport
    record.update_columns(discarded_at: nil, created_at: hours_ago.hours.ago)
    record
  end

  # Seeds five stocks with the Task 2 codes (SKU-0000 available 0, SKU-NEG1 -2,
  # SKU-LOW1 1 with location "A-01-03", SKU-LOW2 10, SKU-FULL 11 — every other
  # location nil), the exports EXP-001 (12, confirmed, 3.hours.ago) and EXP-002
  # (40, shipped, 2.hours.ago), and `imports` imports created 1..n hours ago so
  # the newest has the smallest index (default: IMP-001 120 in_progress 2.hours.ago,
  # IMP-002 30 received 1.hour.ago). with_other_warehouse: also seed one stock
  # (code SKU-OTHER), one import (IMP-OTHER), and one export (EXP-OTHER) in a
  # second warehouse of the same company.
  def call_payload(now: Time.current, bucket: "all", q: nil, imports: 2, with_other_warehouse: false)
    create_stock(code: "SKU-0000", name: "Zero Paste", quantity: 0, pending: 0)
    create_stock(code: "SKU-NEG1", name: "Short Paste", quantity: 3, pending: 5)
    create_stock(code: "SKU-LOW1", name: "Low Wire", quantity: 1, pending: 0, location: "A-01-03")
    create_stock(code: "SKU-LOW2", name: "Edge Wire", quantity: 10, pending: 0)
    create_stock(code: "SKU-FULL", name: "Full Board", quantity: 11, pending: 0)

    create_document(StockExport, code: "EXP-001", quantity: 12, status: :confirmed, hours_ago: 3)
    create_document(StockExport, code: "EXP-002", quantity: 40, status: :shipped, hours_ago: 2)

    if imports == 2
      create_document(StockImport, code: "IMP-001", quantity: 120, status: :in_progress, hours_ago: 2)
      create_document(StockImport, code: "IMP-002", quantity: 30, status: :received, hours_ago: 1)
    else
      imports.downto(1) do |index|
        create_document(StockImport, code: "IMP-#{index}", quantity: index * 10,
          status: :in_progress, hours_ago: index)
      end
    end

    if with_other_warehouse
      create_stock(code: "SKU-OTHER", name: "Other Paste", quantity: 0, pending: 0, warehouse: other_warehouse)
      create_document(StockImport, code: "IMP-OTHER", quantity: 999, status: :received,
        hours_ago: 1, warehouse: other_warehouse)
      create_document(StockExport, code: "EXP-OTHER", quantity: 999, status: :shipped,
        hours_ago: 1, warehouse: other_warehouse)
    end

    described_class.call(company: company, appointment: appointment, q: q, bucket: bucket, now: now)
      .deep_symbolize_keys
  end

  it "counts the warehouse, its short rows, and its outs" do
    payload = call_payload

    expect(payload.dig(:kpis, :stock_rows)).to eq(5)
    expect(payload.dig(:kpis, :low_or_out)).to eq(4)
    expect(payload.dig(:kpis, :out)).to eq(2)
    expect(payload.dig(:kpis, :minimum)).to eq(LOW_STOCK_THRESHOLD)
  end

  it "reports inbound and outbound units as the plain sum of the listed documents" do
    payload = call_payload

    expect(payload.dig(:kpis, :recent_inbound)).to eq(count: 2, units: 150)
    expect(payload.dig(:kpis, :recent_outbound)).to eq(count: 2, units: 52)
    expect(payload[:recent_outbound].map { _1[:quantity] }).to eq([ 40, 12 ])
    expect(payload[:recent_inbound].first).to include(code: "IMP-002", status_label: "Received", quantity: 30)
  end

  it "keeps the KPI count equal to the records the list shows" do
    payload = call_payload(imports: 6)

    expect(payload[:recent_inbound].length).to eq(4)
    expect(payload.dig(:kpis, :recent_inbound, :count)).to eq(4)
    expect(payload.dig(:kpis, :recent_inbound, :units)).to eq(payload[:recent_inbound].sum { _1[:quantity] })
  end

  it "never invents dock, packaging, weight, or percentage fields" do
    payload = call_payload

    expect(payload[:recent_inbound].first.keys)
      .to contain_exactly(:id, :code, :status, :status_label, :quantity, :occurred_at)
    expect(payload[:recent_outbound].first.keys)
      .to contain_exactly(:id, :code, :status, :status_label, :quantity, :occurred_at)
    expect(payload.keys).not_to include(:docks, :zones, :audit, :metrics, :global_utilization)
  end

  it "reports the cycle-count gap with the real row count" do
    payload = call_payload

    expect(payload[:cycle_counts]).to eq(available: false, stock_rows: 5)
  end

  it "keeps a blank location blank and reports the ISO server clock" do
    payload = call_payload(now: Time.utc(2026, 11, 20, 9, 0, 0))

    expect(payload[:generated_at]).to eq("2026-11-20T09:00:00Z")
    expect(payload[:ledger][:rows].map { _1[:location] }).to contain_exactly("A-01-03", nil, nil, nil, nil)
  end

  it "passes the ledger view through" do
    payload = call_payload(bucket: "low")

    expect(payload[:ledger]).to include(bucket: "low", q: "", limit: Inventory::LedgerScope::LEDGER_LIMIT)
    expect(payload[:ledger][:total]).to eq(2)
    expect(payload[:ledger][:rows].map { _1[:code] }).to contain_exactly("SKU-LOW1", "SKU-LOW2")
  end

  it "excludes other warehouses from every figure" do
    payload = call_payload(with_other_warehouse: true)

    expect(payload.dig(:kpis, :stock_rows)).to eq(5)
    expect(payload[:recent_inbound].map { _1[:code] }).not_to include("IMP-OTHER")
    expect(payload[:recent_outbound].map { _1[:code] }).not_to include("EXP-OTHER")
    expect(payload[:ledger][:rows].map { _1[:code] }).not_to include("SKU-OTHER")
  end
end
