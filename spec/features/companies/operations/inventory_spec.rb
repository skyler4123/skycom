# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::Operations::Inventory", type: :feature, js: true do
  let(:company_user) { create(:user, :company_owner) }
  let(:company) { Seed::CompanyService.new(user: company_user, country: :us, business_type: :retail).tap(&:save!) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company, name: "BR-01 Central Hub", code: "BR-01") }
  let!(:warehouse) { Seed::WarehouseService.create(company: company, branch: branch, name: "WH-01 Central", code: "WH-01") }
  let!(:empty_warehouse) { Seed::WarehouseService.create(company: company, branch: branch, name: "WH-02 Empty", code: "WH-02") }
  let(:operation) do
    company.operations.find_by(operation_type: :inventory) ||
      create(:operation, company: company, operation_type: :inventory)
  end
  let!(:appointment) do
    OperationWarehouseAppointment.find_or_create_by!(company: company, operation: operation, warehouse: warehouse)
  end
  let!(:empty_appointment) do
    OperationWarehouseAppointment.find_or_create_by!(company: company, operation: operation, warehouse: empty_warehouse)
  end
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "stocks") }
  let(:inventory_path) do
    "/companies/#{company.id}/operations/inventory/#{operation.id}?warehouse_id=#{warehouse.id}"
  end

  def create_stock(name:, code:, quantity:, pending:, location: nil, price_cents: nil)
    product = create(:product, company: company, name: name)
    Stock.create!(company: company, warehouse: warehouse, branch: branch, product: product,
      category: category, property_mapping: category.default_property_mapping,
      name: name, code: code, quantity: quantity, pending: pending,
      property_string_1: location, price_cents: price_cents)
  end

  def create_document(klass, code:, quantity:, status:, hours_ago:)
    product = create(:product, company: company)
    service = klass == StockImport ? Seed::StockImportService : Seed::StockExportService
    record = service.create(company: company, branch: branch, warehouse: warehouse,
      product: product, code: code, quantity: quantity, workflow_status: status)
    record.update_columns(discarded_at: nil, created_at: hours_ago.hours.ago)
    record
  end

  let!(:in_stock_row) do
    create_stock(name: "Micro-Controller PCB v2.4", code: "SKU-ELEC-9021", quantity: 50, pending: 5,
      location: "A-01-03", price_cents: 1250)
  end
  let!(:low_stock_row) do
    create_stock(name: "Copper Wire Spool", code: "SKU-WIRE-4410", quantity: 12, pending: 4)
  end
  let!(:out_stock_row) do
    create_stock(name: "Thermal Paste", code: "SKU-PASTE-7781", quantity: 3, pending: 3, location: "B-02")
  end

  before do
    create_document(StockImport, code: "IMP-TEST-001", quantity: 120, status: :in_progress, hours_ago: 2)
    create_document(StockImport, code: "IMP-TEST-002", quantity: 30, status: :received, hours_ago: 1)
    create_document(StockExport, code: "EXP-TEST-001", quantity: 12, status: :confirmed, hours_ago: 2)
    create_document(StockExport, code: "EXP-TEST-002", quantity: 40, status: :shipped, hours_ago: 1)
    sign_in(owner)
  end

  scenario "renders one page with four real KPIs and none of the retired chrome" do
    visit inventory_path

    find('[data-operation-block="kpis"]', wait: 10)

    expect(find('[data-kpi="stock_rows"]')).to have_content("3")
    expect(find('[data-kpi="low_or_out"]')).to have_content("2")
    expect(find('[data-kpi="low_or_out"]')).to have_content("1 out")
    expect(find('[data-kpi="recent_inbound"]')).to have_content("2")
    expect(find('[data-kpi="recent_inbound"]')).to have_content("150 units")
    expect(find('[data-kpi="recent_outbound"]')).to have_content("2")
    expect(find('[data-kpi="recent_outbound"]')).to have_content("52 units")

    inbound_card = find('[data-operation-block="recent-inbound"]')
    expect(inbound_card).to have_content("IMP-TEST-002")
    expect(inbound_card).to have_content("Received")
    expect(inbound_card).to have_content("30 units")
    expect(inbound_card).to have_no_content("Gate")
    expect(inbound_card).to have_no_content("%")

    outbound_card = find('[data-operation-block="recent-outbound"]')
    expect(outbound_card).to have_content("EXP-TEST-002")
    expect(outbound_card).to have_content("Shipped")
    expect(outbound_card).to have_content("40 units")
    expect(outbound_card).to have_no_content("kg")

    expect(page).to have_content("WH-01 Central")
    expect(page).to have_content("WH-01")
    expect(page).to have_content("BR-01 Central Hub")
    expect(page).to have_content(company.name)
    expect(page).to have_link("Open receiving", href: new_company_stock_import_path(company))
    expect(page).to have_link("Open transfer", href: new_company_stock_transfer_path(company))
    expect(page).to have_link("Open stock list", href: company_stocks_path(company))

    [
      "Store Overview", "Counter & POS Terminals", "Orders & Fulfillment", "Store Replenishment",
      "Warehouse Transfers", "BOM & Procurement", "BOM Line Shortage", "Zone Capacity Map",
      "RFID", "Cloud Sync Active", "Primary Fulfillment Node", "Sync: Real-time",
      "Stock Row Utilization", "Freight Gates", "Density", "Audit Cycle Count", "Schedule Count",
      "Re-optimize", "Auto-Generate Bulk POs", "View Full Audit Log", "Active Freight Docks",
      "Cartons", "pallets", " kg", "Cycle verified"
    ].each do |gone|
      expect(page).to have_no_content(gone), "expected #{gone.inspect} to be gone"
    end
  end

  scenario "renders every ledger column from the record" do
    visit inventory_path

    ledger = find('[data-operation-block="ledger"]', wait: 10)
    within(ledger) do
      %w[Product Location On\ hand Reserved Available Minimum Status Open].each do |heading|
        expect(page).to have_content(/#{Regexp.escape(heading)}/i)
      end

      in_stock_cells = find("tbody tr", text: "Micro-Controller PCB v2.4").all("td").map(&:text)
      expect(in_stock_cells.length).to eq(8)
      expect(in_stock_cells[0]).to include("SKU-ELEC-9021")
      expect(in_stock_cells[0]).to include("$12.50")
      expect(in_stock_cells[1]).to eq("A-01-03")
      expect(in_stock_cells[2]).to eq("50")
      expect(in_stock_cells[3]).to eq("5")
      expect(in_stock_cells[4]).to eq("45")
      expect(in_stock_cells[5]).to eq("10")
      expect(in_stock_cells[6]).to include("In stock")

      low_cells = find("tbody tr", text: "Copper Wire Spool").all("td").map(&:text)
      expect(low_cells[1]).to eq("—")
      expect(low_cells[4]).to eq("8")
      expect(low_cells[6]).to include("Low")

      out_cells = find("tbody tr", text: "Thermal Paste").all("td").map(&:text)
      expect(out_cells[4]).to eq("0")
      expect(out_cells[6]).to include("Out")

      expect(page).to have_content("Showing 3 of 3")
      expect(page).to have_link("Open", href: company_stock_path(company, out_stock_row))
    end
  end

  scenario "tabs are disjoint and add up to All" do
    visit inventory_path

    within("#inventory-ledger-tabs", wait: 10) do
      expect(page).to have_button("All (3)")
      expect(page).to have_button("Low (1)")
      expect(page).to have_button("Out (1)")
      expect(page).to have_button("In stock (1)")
    end

    click_button "Low (1)"
    expect(page).to have_content("Copper Wire Spool", wait: 10)
    expect(page).to have_no_content("Micro-Controller PCB v2.4")

    click_button "Out (1)"
    expect(page).to have_content("Thermal Paste", wait: 10)
    expect(page).to have_no_content("Copper Wire Spool")

    click_button "All (3)"
    expect(page).to have_content("Micro-Controller PCB v2.4", wait: 10)
  end

  scenario "search hits the warehouse by name, code, and location" do
    Stock.ms_clear_index!
    Stock.find_each { _1.ms_index!(true) }
    visit inventory_path
    expect(page).to have_content("Micro-Controller PCB v2.4", wait: 10)

    fill_in "inventory-stock-search", with: "Copper"
    expect(page).to have_content("Copper Wire Spool", wait: 10)
    expect(page).to have_no_content("Thermal Paste")

    fill_in "inventory-stock-search", with: "A-01-03"
    expect(page).to have_content("Micro-Controller PCB v2.4", wait: 10)
    expect(page).to have_no_content("Copper Wire Spool")

    fill_in "inventory-stock-search", with: "SKU-NOPE"
    expect(page).to have_content("No stock rows match this view.", wait: 10)
  ensure
    Stock.ms_clear_index!
  end

  scenario "the export link follows the selected tab and search" do
    visit inventory_path

    click_button "Low (1)"
    expect(page).to have_link("Export CSV", href: %r{/ledger\?.*bucket=low}, wait: 10)

    fill_in "inventory-stock-search", with: "Copper"
    expect(page).to have_link("Export CSV", href: %r{q=Copper}, wait: 10)
  end

  scenario "says the list is capped and points at the stock list" do
    stub_const("Inventory::LedgerScope::LEDGER_LIMIT", 1)
    visit inventory_path

    footer = find("#inventory-ledger-footer", wait: 10)
    expect(footer).to have_content("Showing 1 of 3")
    expect(footer).to have_content("This list is capped.")
    expect(footer).to have_link("Open stock list", href: company_stocks_path(company))
  end

  scenario "refresh rewrites the server-clock Updated line" do
    travel_to Time.utc(2026, 11, 20, 9, 0) do
      visit inventory_path
      expect(page).to have_content("20 Nov 2026, 09:00", wait: 10)

      travel 5.minutes
      click_button "Refresh"
      expect(page).to have_content("20 Nov 2026, 09:05", wait: 10)
    end
  end

  scenario "shows honest empty states for a warehouse with no records" do
    visit "/companies/#{company.id}/operations/inventory/#{operation.id}?warehouse_id=#{empty_warehouse.id}"

    expect(page).to have_content("No stock rows match this view.", wait: 10)
    expect(page).to have_content("No recent receipts.")
    expect(page).to have_content("No recent dispatches.")
    expect(page).to have_content("Cycle counts are not available yet.")
    expect(page).to have_content("0 stock rows are in this warehouse.")
    expect(page).to have_no_content("Schedule Count")
  end

  scenario "spans the full viewport width on a wide desktop console" do
    with_window_size(1920, 1080) do
      visit inventory_path
      expect(page).to have_content("Stock ledger", wait: 10)

      metrics = console_layout_metrics
      expect(metrics["main_width"]).to be_within(1).of(metrics["viewport_width"])
      expect(metrics["header_width"]).to be_within(1).of(metrics["viewport_width"])
      expect(metrics["scroll_width"]).to be <= metrics["viewport_width"]
    end
  end
end
