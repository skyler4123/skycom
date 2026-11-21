# frozen_string_literal: true

require "rails_helper"

RSpec.describe StoreManager::ShelfQueryService, type: :service do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company, timezone: :utc) }
  let(:warehouse) { create(:warehouse, company: company, branch: branch, name: "Branch 1 Warehouse") }
  let(:source_warehouse) { create(:warehouse, company: company, branch: branch, name: "Central Warehouse") }
  let(:product) { create(:product, company: company, name: "MX Master 3S", code: "LOGI-MX3S") }
  let(:other_product) { create(:product, company: company, name: "Plain Mouse", code: "PLAIN-1") }

  it "uses the product reorder rule and falls back to the default minimum" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      create(:reorder_rule, company: company, product: product, warehouse: warehouse,
        min_quantity: 12, safety_stock: 4)
      create_store_stock(company: company, branch: branch, warehouse: warehouse, product: product,
        quantity: 5, code: "LOGI-MX3S")
      create_store_stock(company: company, branch: branch, warehouse: warehouse, product: other_product,
        quantity: 2, code: "PLAIN-1")
      create_store_stock(company: company, branch: branch, warehouse: source_warehouse, product: product,
        quantity: 20, code: "LOGI-MX3S-CENTRAL")

      payload = described_class.call(
        company: company, branch: branch, date: Date.new(2026, 11, 20),
        now: Time.utc(2026, 11, 20, 10, 0, 0)
      )

      ruled = payload[:rows].find { |row| row[:sku] == "LOGI-MX3S" }
      defaulted = payload[:rows].find { |row| row[:sku] == "PLAIN-1" }

      expect(ruled).to include(threshold: 16, default_minimum: false, shelf_quantity: 5,
        warehouse_available: 20, source_warehouse_name: "Central Warehouse", action_key: "transfer")
      expect(defaulted).to include(threshold: LOW_STOCK_THRESHOLD, default_minimum: true)
      expect(payload[:reorder_rules_present]).to be(true)
    end
  end

  it "opens the existing transfer instead of offering a second request" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      stock = create_store_stock(company: company, branch: branch, warehouse: warehouse, product: product,
        quantity: 2, code: "LOGI-MX3S")
      source = create_store_stock(company: company, branch: branch, warehouse: source_warehouse, product: product,
        quantity: 10, code: "LOGI-MX3S-CENTRAL")
      result = Inventory::TransferService.transfer(
        company: company, warehouse: source_warehouse, employee: create(:employee, company: company, branch: branch),
        stock_id: source.id, quantity: 3, destination_warehouse_id: warehouse.id
      )

      payload = described_class.call(
        company: company, branch: branch, date: Date.new(2026, 11, 20),
        now: Time.utc(2026, 11, 20, 10, 0, 0)
      )

      row = payload[:rows].find { |candidate| candidate[:stock_id] == stock.id }
      expect(row).to include(
        stage_key: "transfer",
        stage_label: "Transfer #{result[:code]}",
        document_type: "transfer",
        document_code: result[:code],
        action_key: "open",
        action_label: "Open transfer"
      )
      expect(row[:document_path]).to include("/stock_transfers/")
    end
  end

  it "reads the saved snapshot on a past date" do
    close = create(:shift_close, company: company, branch: branch, business_date: Date.new(2026, 11, 19),
      shelf_snapshot: [ { "product_name" => "Old SKU", "shelf_quantity" => 1, "threshold" => 10 } ])

    payload = described_class.call(
      company: company, branch: branch, date: Date.new(2026, 11, 19),
      now: Time.utc(2026, 11, 20, 10, 0, 0), shift_close: close
    )

    expect(payload[:snapshot_missing]).to be(false)
    expect(payload[:rows].first).to include(product_name: "Old SKU", shelf_quantity: 1, read_only: true)
  end

  it "says the snapshot is missing when a past date has no close" do
    payload = described_class.call(
      company: company, branch: branch, date: Date.new(2026, 11, 19),
      now: Time.utc(2026, 11, 20, 10, 0, 0)
    )

    expect(payload[:snapshot_missing]).to be(true)
    expect(payload[:rows]).to be_empty
  end
end
