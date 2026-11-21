# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::Operations::StoreManagerController", type: :request do
  let(:company) { create(:company, currency: :usd) }
  let(:owner) { company.user }
  let(:owner_employee) { company.employees.find_by!(user: owner) }
  let!(:branch) { create(:branch, company: company, name: "Downtown Flagship", timezone: :utc) }
  let!(:warehouse) { create(:warehouse, company: company, branch: branch, name: "WH-01 Central") }
  let!(:operation) { Seed::OperationService.create(company: company, operation_type: :store_manager) }
  let(:appointment) { operation.branch_operation_appointments.find_by!(branch: branch) }
  let(:customer) { create(:customer, company: company, branch: branch, name: "Marcus Vance") }
  let(:product) { create(:product, company: company, name: "MX Master 3S", code: "LOGI-MX3S") }

  before do
    get sign_in_for_test_path(email: owner.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  def store_path(**params)
    store_manager_company_operations_path(company, operation, { branch_id: branch.id }.merge(params))
  end

  it "returns the live console payload" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      order, = create_store_invoice_order(
        company: company, branch: branch, employee: owner_employee,
        total_cents: 11_000, tax_cents: 1_000, tender: :cash,
        cash_received_cents: 12_000, change_cents: 1_000
      )
      create_store_stock(company: company, branch: branch, warehouse: warehouse, product: product,
        quantity: 2, code: "LOGI-MX3S")
      create_store_shift(
        company: company, branch: branch, employee: owner_employee, name: "Morning",
        starts_at: Time.utc(2026, 11, 20, 8, 0, 0), ends_at: Time.utc(2026, 11, 20, 17, 0, 0)
      )

      get store_path(format: :json)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      payload = body.fetch("store_manager")
      expect(body["coming_soon"]).to be(false)
      expect(payload.dig("branch", "name")).to eq("Downtown Flagship")
      expect(payload.dig("kpis", "gross_sales_cents")).to eq(11_000)
      expect(payload.dig("kpis", "cashiers_count")).to eq(1)
      expect(payload.dig("kpis", "paid_orders_count")).to eq(1)
      expect(payload.dig("kpis", "shelf_alerts")).to eq(1)
      expect(payload.dig("kpis", "staff_on_duty")).to eq(1)
      expect(payload.dig("queue", "orders", 0, "code")).to eq(order.code)
      expect(payload.dig("shelf", "rows", 0, "sku")).to eq("LOGI-MX3S")
      expect(payload.dig("shift", "name")).to eq("Morning")
      expect(payload.dig("shift_close", "saved")).to be(false)
      expect(payload["generated_at"]).to be_present
    end
  end

  it "serves the queue page and code search" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      order = create(:order, company: company, branch: branch, customer: customer,
        name: "Queue Order #{SecureRandom.hex(4)}", workflow_status: :pending,
        fulfillment_channel: :click_collect, created_at: Time.utc(2026, 11, 20, 9, 0, 0))
      order.update_columns(discarded_at: nil)

      get store_manager_queue_company_operations_path(company, operation, branch_id: branch.id, q: order.code, format: :json)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["orders"].map { |row| row["code"] }).to eq([ order.code ])
      expect(body.dig("pagination", "count")).to eq(1)
    end
  end

  it "marks an order ready and hands it over" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      order, = create_store_invoice_order(
        company: company, branch: branch, employee: owner_employee,
        workflow_status: :paid, channel: :click_collect
      )

      post store_manager_order_mark_ready_company_operations_path(company, operation, order), params: { branch_id: branch.id }, as: :json
      expect(response).to have_http_status(:ok)
      expect(order.reload.fulfillment_status).to eq("ready")

      post store_manager_order_hand_over_company_operations_path(company, operation, order), params: { branch_id: branch.id }, as: :json
      expect(response).to have_http_status(:ok)
      expect(order.reload.fulfillment_status).to eq("handed_over")
      expect(order.handed_over_at).to be_present
      expect(JSON.parse(response.body)["message"]).to include("handed over")
    end
  end

  it "blocks handover until the order is paid" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      order = create(:order, company: company, branch: branch, customer: customer,
        name: "Unpaid Order #{SecureRandom.hex(4)}", workflow_status: :pending,
        fulfillment_channel: :click_collect, created_at: Time.utc(2026, 11, 20, 9, 0, 0))
      order.update_columns(discarded_at: nil)

      post store_manager_order_hand_over_company_operations_path(company, operation, order), params: { branch_id: branch.id }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to include("Order must be paid at POS before handover.")
    end
  end

  it "creates and reuses a transfer for a low shelf row" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      stock = create_store_stock(company: company, branch: branch, warehouse: warehouse, product: product,
        quantity: 2, code: "LOGI-MX3S")
      source = create(:warehouse, company: company, branch: branch, name: "Central")
      create_store_stock(company: company, branch: branch, warehouse: source, product: product,
        quantity: 10, code: "LOGI-MX3S-CENTRAL")

      post store_manager_replenishments_company_operations_path(company, operation),
        params: { branch_id: branch.id, replenishment: { stock_id: stock.id } }, as: :json
      expect(response).to have_http_status(:ok)
      first = JSON.parse(response.body)
      expect(first.dig("document", "type")).to eq("transfer")

      post store_manager_replenishments_company_operations_path(company, operation),
        params: { branch_id: branch.id, replenishment: { stock_id: stock.id } }, as: :json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["existing"]).to be(true)
      expect(company.stock_transfers.count).to eq(1)
    end
  end

  it "saves the close and refuses a past date" do
    travel_to Time.utc(2026, 11, 20, 17, 0, 0) do
      create_store_invoice_order(
        company: company, branch: branch, employee: owner_employee,
        total_cents: 11_000, tender: :cash, cash_received_cents: 11_000, change_cents: 0
      )

      post store_manager_shift_close_company_operations_path(company, operation),
        params: { branch_id: branch.id, shift_close: { opening_float_cents: 5_000, counted_cash_cents: 16_000, note: nil } },
        as: :json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("shift_close", "variance_cents")).to eq(0)

      post store_manager_shift_close_company_operations_path(company, operation),
        params: { branch_id: branch.id, date: "2026-11-19", shift_close: { opening_float_cents: 0, counted_cash_cents: 0 } },
        as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to include("Only today's shift can be closed.")
    end
  end

  it "rejects a future date" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      get store_path(date: "2026-11-21", format: :json)

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to include("Future dates are not available.")
    end
  end

  it "does not expose another company's order" do
    other_company = create(:company)
    other_order = create(:order, company: other_company, customer: create(:customer, company: other_company))

    post store_manager_order_mark_ready_company_operations_path(company, operation, other_order), params: { branch_id: branch.id }, as: :json

    expect(response).to have_http_status(:not_found)
  end

  it "returns 403 for another company's operation" do
    other_company = create(:company)
    other_operation = Seed::OperationService.create(company: other_company, operation_type: :store_manager)

    get store_manager_company_operations_path(other_company, other_operation),
      params: { branch_id: branch.id }, as: :json

    expect(response).to have_http_status(:forbidden)
    expect(JSON.parse(response.body)["errors"]).to include("You are not authorized to perform this action.")
  end
end
