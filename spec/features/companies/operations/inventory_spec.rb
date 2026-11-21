# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::Operations::Inventory", type: :feature, js: true do
  let(:company_user) { create(:user, :company_owner) }
  let(:company) { Seed::CompanyService.new(user: company_user, country: :us, business_type: :retail).tap(&:save!) }
  let(:owner) { company.user }
  let(:owner_employee) { company.employees.find_by!(user: owner) }
  let(:branch) { create(:branch, company: company, name: "Grocery VN") }
  let!(:operation) { Seed::OperationService.create(company: company, operation_type: :inventory) }
  let!(:warehouse) { Seed::WarehouseService.create(company: company, branch: branch, name: "Branch 1 Warehouse", code: "WH-01") }
  let(:product) { create(:product, company: company, name: "Product 1", code: "SKU-001", business_type: :physical) }

  def inventory_path(warehouse_id: warehouse.id)
    inventory_company_operations_path(company, operation, warehouse_id: warehouse_id)
  end

  def create_stock(quantity:, pending: 0, location: "A-01", record_product: product, target_warehouse: warehouse)
    stock = Seed::StockService.create(
      company: company,
      warehouse: target_warehouse,
      branch: branch,
      product_id: record_product.id,
      name: record_product.name,
      code: record_product.code,
      quantity: quantity,
      pending: pending,
      discarded_at: nil
    )
    stock.update!(discarded_at: nil, property_string_1: location)
    stock
  end

  def stock_row(stock)
    find("[data-stock-row][data-stock-code='#{stock.code}']")
  end

  before { sign_in(owner) }

  scenario "renders the quiet shell, four real KPIs and no invented controls" do
    create_stock(quantity: 18, pending: 12)
    create_stock(quantity: 0, location: nil, record_product: create(:product, company: company, name: "Product 2", code: "SKU-002", business_type: :physical))
    create_stock(quantity: 50, record_product: create(:product, company: company, name: "Product 3", code: "SKU-003", business_type: :physical))

    create(:stock_import, company: company, warehouse: warehouse, product: product, quantity: 25,
      workflow_status: :draft, code: "IMP-OPEN-1")
    create(:stock_export, company: company, warehouse: warehouse, product: product, quantity: 4,
      workflow_status: :confirmed, code: "EXP-OPEN-1")
    count = StockCount.create!(
      company: company, warehouse: warehouse, count_type: :cycle, status: :completed,
      started_at: 1.hour.ago, completed_at: 30.minutes.ago,
      metadata: { "completed_by_name" => "Warehouse Lead" }
    )
    count.stock_count_lines.create!(
      company: company, stock: company.stocks.find_by!(product_id: product.id),
      expected_quantity: 18, counted_quantity: 17, variance_quantity: -1
    )

    visit inventory_path

    within(find('[data-operation-block="kpis"]', wait: 10)) do
      expect(page).to have_content("STOCK ROWS")
      expect(page).to have_content("3")
      expect(page).to have_content("NEEDS ATTENTION")
      expect(page).to have_content("2")
      expect(page).to have_content("INBOUND OPEN")
      expect(page).to have_content("1")
      expect(page).to have_content("OUTBOUND OPEN")
      expect(page).to have_content("1")
    end

    within(find('[data-operation-block="ledger"]', wait: 10)) do
      expect(page).to have_content("Stock")
      expect(page).to have_content("On hand, reserved, and available for Branch 1 Warehouse.")
      expect(page).to have_content(/reorder at/i)
      expect(page).to have_content("Same reorder point for every item: 10")
    end

    within(find('[data-operation-block="last-count"]', wait: 10)) do
      expect(page).to have_content("Last count")
      expect(page).to have_content("Warehouse Lead")
      expect(page).to have_content("Net variance")
    end

    expect(page).to have_content("Last refreshed")
    expect(page).to have_no_content("Store Overview")
    expect(page).to have_no_content("BOM")
    expect(page).to have_no_content("Zone Capacity")
    expect(page).to have_no_content("Cloud Sync")
    expect(page).to have_no_content("Primary Fulfillment Node")
    expect(page).to have_no_content("RFID")
    expect(page).to have_no_content("Density")
    expect(page).to have_no_content("Gate")
    expect(page).to have_no_content("Bay")
    expect(page).to have_no_content("pallets")
    expect(page).to have_no_content("cartons")
    expect(page).to have_no_content("kg")
    expect(page).to have_no_content("Cycle verified")
    expect(page).to have_no_content("coming soon")
  end

  scenario "shows on hand, reserved, available, reorder point, status and a real location" do
    low = create_stock(quantity: 18, pending: 12, location: "A-01")
    missing = create_stock(quantity: 50, location: nil,
      record_product: create(:product, company: company, name: "Product 2", code: "SKU-002", business_type: :physical))

    visit inventory_path

    within(stock_row(low)) do
      expect(page).to have_content("Product 1")
      expect(page).to have_content("SKU-001")
      expect(page).to have_content("A-01")
      expect(page).to have_content("18")
      expect(page).to have_content("12")
      expect(page).to have_content("6")
      expect(page).to have_content("10")
      expect(page).to have_content("Low")
      expect(page).to have_button("Adjust")
      expect(page).to have_button("Reorder")
    end

    within(stock_row(missing)) do
      expect(page).to have_content("No location")
      expect(page).to have_content("In stock")
      expect(page).to have_no_button("Reorder")
    end

    find("#inventory-stock-tabs [data-filter='low']").click
    expect(page).to have_selector("[data-stock-code='SKU-001']", wait: 10)
    expect(page).to have_no_selector("[data-stock-code='SKU-002']")

    find("#inventory-stock-tabs [data-filter='out']").click
    expect(page).to have_content("No stock rows match this view.", wait: 10)

    find("#inventory-stock-tabs [data-filter='in_stock']").click
    expect(page).to have_selector("[data-stock-code='SKU-002']", wait: 10)
    expect(page).to have_no_selector("[data-stock-code='SKU-001']")
  end

  scenario "paginates on the server and finds an exact SKU past the first page" do
    52.times do |index|
      record_product = create(:product, company: company, name: "Item #{index.to_s.rjust(3, "0")}",
        code: "SKU-#{index.to_s.rjust(3, "0")}", business_type: :physical)
      create_stock(quantity: 100, record_product: record_product)
    end

    visit inventory_path

    within(find('[data-operation-block="ledger"]', wait: 10)) do
      expect(page).to have_content("Showing 1–50 of 52")
      click_button "Next"
      expect(page).to have_content("Showing 51–52 of 52", wait: 10)
    end

    fill_in "inventory-stock-search", with: "SKU-051"
    expect(page).to have_selector("[data-stock-code='SKU-051']", wait: 10)
    expect(page).to have_no_selector("[data-stock-code='SKU-001']")
    expect(page).to have_content("Showing 1–1 of 1")

    fill_in "inventory-stock-search", with: "NOPE"
    expect(page).to have_content("Code not found: NOPE", wait: 10)
  end

  scenario "receive posts a real receipt and updates the ledger and inbound stack" do
    stock = create_stock(quantity: 10)

    visit inventory_path
    within(find('[data-operation-block="context"]', wait: 10)) { click_button "Receive" }

    within(find('[data-operation-block="drawer"]', wait: 10)) do
      expect(page).to have_content("Receive into Branch 1 Warehouse")
      find("[data-stock-id='#{stock.id}']", wait: 10).click
      fill_in "inventory-receipt-quantity", with: "10"
      fill_in "inventory-receipt-location", with: "B-02"
      click_button "Post receipt"
    end

    expect(page).to have_content("Received 10", wait: 10)
    expect(stock.reload.quantity).to eq(20)
    expect(stock.property_string_1).to eq("B-02")
    within(stock_row(stock)) { expect(page).to have_content("20") }
    within(find('[data-operation-block="inbound"]', wait: 10)) { expect(page).to have_content("Received") }
  end

  scenario "resumes an open import in the same drawer" do
    stock = create_stock(quantity: 10)
    import = create(:stock_import, company: company, warehouse: warehouse, product: product,
      quantity: 0, workflow_status: :draft, code: "IMP-RESUME")

    visit inventory_path
    within(find('[data-operation-block="inbound"]', wait: 10)) do
      expect(page).to have_content("IMP-RESUME")
      find("[data-receipt-id='#{import.id}']").click
    end

    within(find('[data-operation-block="drawer"]', wait: 10)) do
      expect(page).to have_content("This receipt has no line items yet.")
      find("[data-stock-id='#{stock.id}']", wait: 10).click
      fill_in "inventory-receipt-quantity", with: "4"
      click_button "Post receipt"
    end

    expect(page).to have_content("Received 4", wait: 10)
    expect(stock.reload.quantity).to eq(14)
    expect(import.reload.workflow_status).to eq("received")
    within(find('[data-operation-block="inbound"]', wait: 10)) do
      expect(page).to have_content("IMP-RESUME")
      expect(page).to have_content("Received")
    end
  end

  scenario "adjust sets the new on hand and stores the reason" do
    stock = create_stock(quantity: 10)

    visit inventory_path
    within(stock_row(stock)) { click_button "Adjust" }

    within(find('[data-operation-block="drawer"]', wait: 10)) do
      fill_in "inventory-adjust-new-on-hand", with: "9"
      select "Damage", from: "inventory-adjust-reason"
      fill_in "inventory-adjust-note", with: "Damaged bag"
      click_button "Post adjustment"
    end

    expect(page).to have_content("on hand 10 → 9", wait: 10)
    expect(stock.reload.quantity).to eq(9)
    expect(company.stock_adjustments.last.reason).to eq("Damage")
    within(stock_row(stock)) { expect(page).to have_content("9") }
  end

  scenario "transfer out holds the source and the destination marks it received" do
    destination = Seed::WarehouseService.create(company: company, branch: branch, name: "Branch 2 Warehouse", code: "WH-02")
    stock = create_stock(quantity: 20)

    visit inventory_path
    within(find('[data-operation-block="context"]', wait: 10)) { click_button "Transfer out" }

    within(find('[data-operation-block="drawer"]', wait: 10)) do
      find("[data-stock-id='#{stock.id}']", wait: 10).click
      fill_in "inventory-transfer-quantity", with: "4"
      select "Branch 2 Warehouse (WH-02)", from: "inventory-transfer-destination"
      click_button "Transfer"
    end

    expect(page).to have_content("Transfer", wait: 10)
    expect(stock.reload.pending).to eq(4)
    expect(stock.quantity).to eq(20)
    transfer = company.stock_transfers.last
    expect(transfer.workflow_status).to eq("initiated")
    within(find('[data-operation-block="outbound"]', wait: 10)) { expect(page).to have_content("In transit") }

    visit inventory_path(warehouse_id: destination.id)
    within(find('[data-operation-block="inbound"]', wait: 10)) do
      expect(page).to have_content(transfer.code)
      click_button "Mark received"
    end

    expect(page).to have_content("received", wait: 10)
    expect(stock.reload.quantity).to eq(16)
    expect(stock.pending).to eq(0)
    expect(company.stocks.find_by!(warehouse: destination, product_id: product.id).quantity).to eq(4)
  end

  scenario "export leaves the company, drops source on hand and labels the card Export" do
    stock = create_stock(quantity: 10)

    visit inventory_path
    within(find('[data-operation-block="context"]', wait: 10)) { click_button "Transfer out" }

    within(find('[data-operation-block="drawer"]', wait: 10)) do
      click_button "Leaving the company"
      find("[data-stock-id='#{stock.id}']", wait: 10).click
      fill_in "inventory-export-quantity", with: "3"
      fill_in "inventory-export-reference", with: "Donation"
      click_button "Export"
    end

    expect(page).to have_content("Exported 3", wait: 10)
    expect(stock.reload.quantity).to eq(7)
    within(find('[data-operation-block="outbound"]', wait: 10)) do
      expect(page).to have_content(/export/i)
      expect(page).to have_content("Shipped")
    end
  end

  scenario "reorder creates a purchase and the row opens the same purchase on the next press" do
    supplier = create(:supplier, company: company, name: "Fresh Foods")
    product.update!(default_supplier: supplier)
    stock = create_stock(quantity: 2)

    visit inventory_path
    within(stock_row(stock)) { click_button "Reorder" }

    within(find('[data-operation-block="drawer"]', wait: 10)) do
      expect(page).to have_content("Short by")
      fill_in "inventory-reorder-quantity", with: "8"
      click_button "Create purchase"
    end

    expect(page).to have_content("drafted", wait: 10)
    purchase = company.purchases.last
    expect(purchase).to be_present
    expect(purchase.business_type).to eq("stock_reorder")
    expect(purchase.purchase_purchase_item_appointments.first.quantity).to eq(8)
    within(stock_row(stock)) do
      expect(page).to have_content("Open purchase")
      expect(page).to have_content(purchase.code)
      expect(page).to have_link("Open purchase #{purchase.code}")
    end
  end

  scenario "count saves progress across a refresh and submits the variance" do
    stock = create_stock(quantity: 10)

    visit inventory_path
    within(find('[data-operation-block="last-count"]', wait: 10)) { click_button "Start count" }

    within(find('[data-operation-block="count-sheet"]', wait: 10)) do
      expect(page).to have_content("Cycle count")
      line = StockCount.last.stock_count_lines.first
      find("[data-count-line-id='#{line.id}']").set("7")
      click_button "Save progress"
    end

    expect(page).to have_content("Count progress saved", wait: 10)
    expect(StockCount.last.stock_count_lines.first.counted_quantity).to eq(7)

    visit inventory_path
    within(find('[data-operation-block="last-count"]', wait: 10)) do
      expect(page).to have_content("Count in progress")
      expect(page).to have_content("1 of 1 entered")
      click_button "Continue count"
    end

    within(find('[data-operation-block="count-sheet"]', wait: 10)) do
      expect(find("[data-count-line-id]").value).to eq("7")
      click_button "Submit count"
    end

    expect(page).to have_no_selector('[data-operation-block="count-sheet"]', wait: 10)
    expect(stock.reload.quantity).to eq(7)
    within(stock_row(stock)) { expect(page).to have_content("7") }
    within(find('[data-operation-block="last-count"]', wait: 10)) do
      expect(page).to have_content(owner_employee.name)
      expect(page).to have_content("Net variance")
      expect(page).to have_content("-3")
    end
  end

  scenario "shows honest empty states and disables Start count with no rows" do
    visit inventory_path

    within(find('[data-operation-block="ledger"]', wait: 10)) do
      expect(page).to have_content("No stock rows match this view.")
    end
    within(find('[data-operation-block="inbound"]', wait: 10)) do
      expect(page).to have_content("Nothing waiting to receive.")
    end
    within(find('[data-operation-block="outbound"]', wait: 10)) do
      expect(page).to have_content("Nothing waiting to leave.")
    end
    within(find('[data-operation-block="last-count"]', wait: 10)) do
      expect(page).to have_content("No count recorded")
      expect(page).to have_content("0 rows in this warehouse.")
      expect(page).to have_button("Start count", disabled: true)
      expect(page).to have_content("Add stock rows before starting a count.")
    end
  end

  scenario "renders the refresh time in the warehouse clock" do
    warehouse.update!(timezone: :plus_7)
    create_stock(quantity: 10)

    travel_to Time.utc(2026, 11, 20, 1, 0, 0) do
      visit inventory_path

      within(find('[data-operation-block="context"]', wait: 10)) do
        expect(page).to have_content("Last refreshed")
        expect(page).to have_content("08:00")
      end
    end
  end

  scenario "spans the full viewport width on a wide desktop console" do
    create_stock(quantity: 10)

    with_window_size(1920, 1080) do
      visit inventory_path
      expect(page).to have_content("Stock", wait: 10)

      metrics = console_layout_metrics
      expect(metrics["main_width"]).to be_within(1).of(metrics["viewport_width"])
      expect(metrics["header_width"]).to be_within(1).of(metrics["viewport_width"])
      expect(metrics["scroll_width"]).to be <= metrics["viewport_width"]
    end
  end
end
