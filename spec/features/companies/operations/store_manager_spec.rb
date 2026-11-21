# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::Operations::StoreManager", type: :feature, js: true do
  let(:company) do
    create(:company, business_type: :retail).tap do |record|
      record.update_columns(currency: Company.currencies[:usd])
    end
  end
  let(:owner) { company.user }
  let(:owner_employee) { company.employees.find_by!(user: owner) }
  let(:branch) { create(:branch, company: company, name: "Branch 1", code: "STORE-1", timezone: :utc) }
  let(:operation) { create(:operation, company: company, branch: branch, operation_type: :store_manager) }
  let(:warehouse) { Seed::WarehouseService.create(company: company, branch: branch, name: "Branch 1 Warehouse", code: "WH-01") }
  let(:product) { create(:product, company: company, name: "MX Master 3S", code: "LOGI-MX3S") }
  let(:cashier) do
    create(:employee, company: company, branch: branch, name: "Lekisha Dare").tap do |record|
      record.update!(lifecycle_status: :active, discarded_at: nil)
    end
  end
  let(:store_manager_path) do
    "/companies/#{company.id}/operations/store_manager/#{operation.id}?branch_id=#{branch.id}"
  end

  before { sign_in(owner) }

  def open_order(channel: :click_collect, created_at: Time.current, customer: nil, name: nil)
    order = create(
      :order,
      company: company,
      branch: branch,
      customer: customer || create(:customer, company: company, branch: branch),
      name: name || "Order #{SecureRandom.hex(6)}",
      workflow_status: :pending,
      fulfillment_channel: channel,
      created_at: created_at
    )
    order.update_columns(discarded_at: nil)
    order
  end

  def paid_order(channel: :click_collect, total_cents: 10_000, tax_cents: 0, tender: :cash,
    cash_received_cents: nil, change_cents: 0, employee: cashier, created_at: Time.current)
    order, = create_store_invoice_order(
      company: company, branch: branch, employee: employee, channel: channel,
      total_cents: total_cents, tax_cents: tax_cents, tender: tender,
      cash_received_cents: cash_received_cents, change_cents: change_cents, created_at: created_at
    )
    order
  end

  def stock_for(quantity:, warehouse_record: warehouse, code: "LOGI-MX3S")
    create_store_stock(
      company: company, branch: branch, warehouse: warehouse_record,
      product: product, quantity: quantity, code: code
    )
  end

  def kpi_value(key)
    find("[data-kpi='#{key}'] [data-kpi-value]", wait: 10).text
  end

  scenario "renders one truthful page with real links and no invented chrome" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      paid_order(total_cents: 10_000, tender: :cash)
      stock_for(quantity: 2)
      create_store_shift(
        company: company, branch: branch, employee: cashier, name: "Morning",
        starts_at: Time.utc(2026, 11, 20, 8, 0, 0), ends_at: Time.utc(2026, 11, 20, 17, 0, 0)
      )

      visit store_manager_path

      expect(page).to have_content("Store overview", wait: 10)
      expect(page).to have_content(/Gross sales/i)
      expect(page).to have_content(/Cashiers/i)
      expect(page).to have_content(/To hand over/i)
      expect(page).to have_content(/Shelf alerts/i)
      expect(page).to have_content(/On duty/i)
      expect(page).to have_content("No door sensor")
      expect(page).to have_content("Morning · 08:00–17:00 · 1 checked in")

      expect(page).to have_no_content("coming soon")
      expect(page).to have_no_content("Cloud Sync")
      expect(page).to have_no_content("Fully Operational")
      expect(page).to have_no_content("Main Counter")
      expect(page).to have_no_content("Synced")
      expect(page).to have_no_content("Diagnostics")

      expect(page).to have_link("New Store Order", href: new_company_order_path(company))
      expect(page).to have_link("Stock Adjustment", href: company_stock_adjustments_path(company))
      expect(page).to have_link("Manage shift attendance", href: company_attendance_months_path(company))
      expect(page).to have_link("Open stock ledger", href: company_stocks_path(company))
      expect(page).to have_link("Open orders", href: company_orders_path(company))

      click_button "Show low stock"
      expect(page).to have_content("Shelf replenishment")

      click_button "Close shift"
      expect(page).to have_content("Sales by tender", wait: 5)
      click_button "Close"
      expect(page).to have_no_content("Sales by tender", wait: 5)
    end
  end

  scenario "uses invoice totals, agrees with the cashier list and shows per-product minimums" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      paid_order(total_cents: 11_000, tax_cents: 1_000, tender: :cash)
      paid_order(total_cents: 5_000, tender: :qr)
      create(:reorder_rule, company: company, product: product, warehouse: warehouse,
        min_quantity: 12, safety_stock: 4)
      stock_for(quantity: 5)
      other_product = create(:product, company: company, name: "Plain Mouse", code: "PLAIN-1")
      create_store_stock(company: company, branch: branch, warehouse: warehouse, product: other_product,
        quantity: 2, code: "PLAIN-1")

      visit store_manager_path

      expect(kpi_value("gross_sales")).to eq("$160.00")
      expect(find("[data-kpi='gross_sales']")).to have_no_content("%")
      expect(kpi_value("cashiers")).to eq("1")
      expect(page).to have_content("2 paid orders")
      expect(find("[data-cashier-id='#{cashier.id}']")).to have_content("Lekisha Dare")
      expect(find("[data-cashier-id='#{cashier.id}']")).to have_content("$160.00")
      expect(find("[data-cashier-id='#{cashier.id}']")).to have_content("2")

      ruled = find("[data-stock-code='LOGI-MX3S']")
      defaulted = find("[data-stock-code='PLAIN-1']")
      expect(ruled).to have_content("16")
      expect(defaulted).to have_content("10")
      expect(page).to have_content("Default minimum: 10")
    end
  end

  scenario "pages and searches the whole day queue, not the first eight rows" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      54.times { open_order }
      target = open_order(name: "Target Customer #{SecureRandom.hex(3)}")
      target.update!(workflow_status: :pending)

      visit store_manager_path

      expect(page).to have_content("Showing 1–50 of 55", wait: 10)
      codes = all("[data-order-code]").map { |row| row[:"data-order-code"] }
      expect(codes.uniq.length).to eq(codes.length)
      expect(page).to have_button("Next")
      click_button "Next"
      expect(page).to have_content("Showing 51–55 of 55", wait: 10)

      fill_in "store-manager-order-search", with: target.code
      expect(page).to have_content(target.code, wait: 10)
      expect(page).to have_content("Showing 1–1 of 1")
      expect(find("[data-order-code]", match: :first)).to be_present

      fill_in "store-manager-order-search", with: "Local Delivery"
      expect(page).to have_content("No orders match this search.", wait: 10)
    end
  end

  scenario "marks an order ready, hands it over and moves it to Completed" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      first = paid_order(total_cents: 10_000, tender: :cash)
      second = paid_order(total_cents: 5_000, tender: :qr)
      unpaid = open_order

      visit store_manager_path

      expect(kpi_value("to_hand_over")).to eq("3")
      within("[data-order-code='#{first.code}']") { click_button "Mark ready" }
      expect(page).to have_content("ready for handover", wait: 10)
      within("[data-order-code='#{first.code}']") { expect(page).to have_content("Ready", wait: 10) }

      within("[data-order-code='#{first.code}']") { click_button "Hand over" }
      expect(page).to have_content("handed over", wait: 10)
      expect(page).to have_css("[data-kpi='to_hand_over'] [data-kpi-value]", text: "2", wait: 10)

      click_button "Completed"
      within("[data-order-code='#{first.code}']") { expect(page).to have_content("Handed over") }
      expect(page).to have_no_css("[data-order-code='#{second.code}']")
      expect(page).to have_no_css("[data-order-code='#{unpaid.code}']")
    end
  end

  scenario "shows the payment block on an unpaid handover row" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      unpaid = open_order

      visit store_manager_path

      within("[data-order-code='#{unpaid.code}']") do
        expect(page).to have_content("Payment due at POS")
        expect(page).to have_no_button("Hand over")
        expect(page).to have_button("Mark ready")
      end
    end
  end

  scenario "creates one transfer from a low shelf row and opens that same document" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      stock_for(quantity: 2)
      source = create(:warehouse, company: company, branch: branch, name: "Central Warehouse")
      create_store_stock(company: company, branch: branch, warehouse: source, product: product,
        quantity: 10, code: "LOGI-MX3S-CENTRAL")

      visit store_manager_path

      within("[data-stock-code='LOGI-MX3S']") { click_button "Request transfer" }
      expect(page).to have_content("Request transfer", wait: 5)
      expect(page).to have_field("store-manager-replenishment-quantity", with: "8")
      click_button "Confirm"

      expect(page).to have_content("Transfer", wait: 10)
      transfer = company.stock_transfers.first
      expect(transfer).to be_present
      within("[data-stock-code='LOGI-MX3S']") do
        expect(page).to have_content("Transfer #{transfer.code}")
        expect(page).to have_link("Open transfer")
      end
      expect(company.stock_transfers.count).to eq(1)
    end
  end

  scenario "searches by customer, focuses the barcode search and clears" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      elena = create(:customer, company: company, branch: branch, name: "Elena Rostova")
      elena.ms_index!(true)
      open_order(customer: elena, name: "Elena mobile order")

      visit store_manager_path
      fill_in "store-manager-order-search", with: "Elena"
      expect(page).to have_content("Elena Rostova", wait: 10)

      click_button "Focus search"
      expect(page.evaluate_script("document.activeElement.id")).to eq("store-manager-order-search")

      fill_in "store-manager-order-search", with: "Nobody"
      expect(page).to have_content("No orders match this search.", wait: 10)
    end
  end

  scenario "creates a purchase draft when the warehouse has no stock" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      supplier = create(:supplier, company: company, name: "Central Supplier")
      product.update!(default_supplier: supplier)
      stock_for(quantity: 2)

      visit store_manager_path

      within("[data-stock-code='LOGI-MX3S']") { click_button "Create purchase" }
      expect(page).to have_content("Create purchase", wait: 5)
      click_button "Confirm"

      expect(page).to have_content("Purchase", wait: 10)
      purchase = company.purchases.first
      expect(purchase).to be_present
      within("[data-stock-code='LOGI-MX3S']") do
        expect(page).to have_content("Purchase #{purchase.code}")
        expect(page).to have_link("Open purchase")
      end
      expect(company.purchases.count).to eq(1)
    end
  end

  scenario "saves a no-cash close and says so" do
    travel_to Time.utc(2026, 11, 20, 17, 0, 0) do
      paid_order(total_cents: 5_000, tender: :qr)

      visit store_manager_path
      click_button "Close shift"
      expect(page).to have_content("No cash sales")
      fill_in "store-manager-counted-cash", with: "0"
      click_button "Save and close"

      expect(page).to have_content("Shift close saved", wait: 10)
      expect(page).to have_content("$0.00")
    end
  end

  scenario "shows a real on-duty roster and the same count on the KPI and chip" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      create_store_shift(
        company: company, branch: branch, employee: cashier, name: "Morning",
        starts_at: Time.utc(2026, 11, 20, 8, 0, 0), ends_at: Time.utc(2026, 11, 20, 17, 0, 0)
      )
      assigned = create(:employee, company: company, branch: branch, name: "Assigned Only")
      ScheduledShift.create!(
        company: company, branch: branch, employee: assigned, work_date: Date.new(2026, 11, 20),
        expected_start_at: Time.utc(2026, 11, 20, 8, 0, 0),
        expected_end_at: Time.utc(2026, 11, 20, 17, 0, 0),
        status: :scheduled
      )

      visit store_manager_path

      expect(kpi_value("on_duty")).to eq("1")
      expect(find("[data-operation-block='roster']")).to have_content("Lekisha Dare")
      expect(find("[data-operation-block='roster']")).to have_no_content("Assigned Only")
      expect(page).to have_content("Morning · 08:00–17:00 · 1 checked in")
    end
  end

  scenario "stores the close figures, reloads the same variance and prints only the sheet" do
    travel_to Time.utc(2026, 11, 20, 17, 0, 0) do
      open_order_record = paid_order(total_cents: 11_000, tax_cents: 1_000, tender: :cash,
        cash_received_cents: 12_000, change_cents: 1_000)

      visit store_manager_path
      click_button "Close shift"

      expect(page).to have_content(open_order_record.code)
      fill_in "store-manager-opening-float", with: "50"
      fill_in "store-manager-counted-cash", with: "155"
      fill_in "store-manager-close-note", with: "Two bills short"
      expect(page).to have_content("$160.00")
      expect(page).to have_content("-$5.00")

      page.execute_script("window.print = () => { window.__printed = true }")
      click_button "Print"
      expect(page.evaluate_script("window.__printed")).to be(true)
      print_root = find("#store-manager-close-print", visible: :all)
      expect(print_root.text(:all)).to include("Variance")
      expect(print_root.text(:all)).to include("-$5.00")
      expect(print_root.text(:all)).to include(open_order_record.code)
      expect(find("[data-store-manager-app]")[:class]).to include("print:hidden")

      click_button "Save and close"
      expect(page).to have_content("Shift close saved", wait: 10)
      expect(page).to have_content("Saved")

      visit store_manager_path
      click_button "Close shift"
      expect(page).to have_field("store-manager-counted-cash", with: "155")
      expect(page).to have_content("-$5.00")
      expect(page).to have_content("Two bills short")
    end
  end

  scenario "scopes the page to yesterday, keeps writes off the past date and opens a saved close read-only" do
    travel_to Time.utc(2026, 11, 21, 10, 0, 0) do
      paid_order(total_cents: 5_000, created_at: Time.utc(2026, 11, 20, 12, 0, 0))
      paid_order(total_cents: 12_000, created_at: Time.utc(2026, 11, 21, 9, 0, 0))
      create(
        :shift_close,
        company: company, branch: branch, business_date: Date.new(2026, 11, 20),
        counted_cash_cents: 5_000, expected_cash_cents: 5_000, variance_cents: 0,
        shelf_short_count: 1,
        shelf_snapshot: [ {
          "product_name" => "Old SKU", "sku" => "OLD-1", "shelf_quantity" => 1,
          "threshold" => 10, "warehouse_available" => 0,
          "stage_key" => "not_requested", "stage_label" => "Not requested",
          "action_key" => "purchase", "action_label" => "Create purchase"
        } ],
        note: "Balanced"
      )

      visit store_manager_path
      expect(kpi_value("gross_sales")).to eq("$120.00")

      page.execute_script("const el = document.getElementById('store-manager-date'); el.value = '2026-11-20'; el.dispatchEvent(new Event('change', { bubbles: true }))")
      expect(page).to have_content("Read-only", wait: 10)
      expect(kpi_value("gross_sales")).to eq("$50.00")
      expect(page).to have_no_button("Close shift")
      expect(page).to have_button("View close report")
      expect(page).to have_content("Old SKU")
      expect(page).to have_content("Read-only")

      click_button "View close report"
      expect(page).to have_field("store-manager-counted-cash", with: "50", disabled: true)
      expect(page).to have_no_button("Save and close")
      click_button "Close"

      page.execute_script("const el = document.getElementById('store-manager-date'); el.value = '2026-11-19'; el.dispatchEvent(new Event('change', { bubbles: true }))")
      expect(page).to have_content("Read-only", wait: 10)
      expect(page).to have_no_button("View close report")
    end
  end

  scenario "keeps typed sheet values through a forced refresh and reports a failed load" do
    travel_to Time.utc(2026, 11, 20, 17, 0, 0) do
      paid_order(total_cents: 10_000, tender: :cash)

      visit store_manager_path
      click_button "Close shift"
      fill_in "store-manager-counted-cash", with: "123"

      page.execute_script("document.querySelector('[data-store-manager-refresh]').click()")
      expect(page).to have_field("store-manager-counted-cash", with: "123")
      click_button "Close"

      page.execute_script("window.fetchJson = () => Promise.reject(new Error('network down'))")
      page.execute_script("document.querySelector('[data-store-manager-refresh]').click()")
      expect(page).to have_content("Update failed", wait: 10)
      expect(kpi_value("gross_sales")).to eq("$100.00")
    end
  end

  scenario "spans the full viewport width on a wide desktop console" do
    with_window_size(1920, 1080) do
      visit store_manager_path
      expect(page).to have_content("Store overview", wait: 10)

      metrics = console_layout_metrics
      expect(metrics["main_width"]).to be_within(1).of(metrics["viewport_width"])
      expect(metrics["header_width"]).to be_within(1).of(metrics["viewport_width"])
      expect(metrics["scroll_width"]).to be <= metrics["viewport_width"]
    end
  end
end
