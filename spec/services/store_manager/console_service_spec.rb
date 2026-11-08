# frozen_string_literal: true

require "rails_helper"

RSpec.describe StoreManager::ConsoleService, type: :service do
  let(:company_user) { create(:user, :company_owner) }
  let(:company) { Seed::CompanyService.new(user: company_user, country: :us, business_type: :retail).tap(&:save!) }
  let(:branch) { create(:branch, company: company, name: "Downtown Flagship", code: "STORE-104") }
  let(:operation) { create(:operation, company: company, branch: branch, operation_type: :store_manager) }
  let(:appointment) { operation.branch_operation_appointments.find_by!(branch: branch) }
  let(:employee) do
    create(:employee, company: company, branch: branch, name: "Marcus Sterling").tap do |record|
      record.update!(lifecycle_status: :active, discarded_at: nil)
    end
  end
  let(:customer) { Seed::CustomerService.create(company: company, branch: branch, name: "Marcus Vance") }
  let(:product) { create(:product, company: company, name: "MX Master 3S Graphite") }
  let(:warehouse) { Seed::WarehouseService.create(company: company, branch: branch, name: "WH-01 Central") }

  def create_order(workflow_status:, business_type:, employee: nil, quantity: 2, unit_price: 50.0)
    order = Seed::OrderService.create(
      company: company,
      branch: branch,
      customer: customer,
      name: "Store order #{SecureRandom.hex(4)}",
      workflow_status: workflow_status,
      business_type: business_type
    )
    order.update!(employee: employee) if employee
    Seed::OrderProductAppointmentService.create(
      company: company,
      order: order,
      product: product,
      quantity: quantity,
      unit_price: unit_price
    )
    order
  end

  def create_low_stock(quantity: 2, pending: 0)
    stock = Seed::StockService.create(
      company: company,
      warehouse: warehouse,
      branch: branch,
      product_id: product.id,
      name: "MX Master 3S Graphite",
      code: "LOGI-MX3S-GRP",
      quantity: quantity,
      pending: pending,
      discarded_at: nil
    )
    stock.update!(discarded_at: nil)
    stock
  end

  it "builds the store console payload from live orders, stock and employees" do
    paid_order = create_order(workflow_status: :paid, business_type: :in_store, employee: employee)
    pending_order = create_order(workflow_status: :pending, business_type: :online, employee: employee)
    create_low_stock

    payload = described_class.call(company: company, appointment: appointment)

    expect(payload[:branch]).to include(name: "Downtown Flagship", code: "STORE-104")
    expect(payload[:kpis][:gross_sales_cents]).to eq(10_000)
    expect(payload[:kpis][:orders_to_fulfill]).to eq(1)
    expect(payload[:kpis][:click_collect_count]).to eq(0)
    expect(payload[:kpis][:delivery_count]).to eq(1)
    expect(payload[:kpis][:shelf_alerts]).to eq(1)
    expect(payload[:kpis][:staff_on_duty]).to eq(1)

    expect(payload[:orders].map { |order| order[:id] }).to contain_exactly(paid_order.id, pending_order.id)
    expect(payload[:orders_total]).to eq(2)
    expect(payload[:order_counts]).to include(all: 2, click_collect: 1, delivery: 1, completed: 1)
    expect(payload[:replenishments].first).to include(
      product_name: "MX Master 3S Graphite",
      shelf_quantity: 2,
      threshold: LOW_STOCK_THRESHOLD,
      stage: "low"
    )
    expect(payload[:registers].first).to include(cashier: "Marcus Sterling", orders_count: 2)
    expect(payload[:staff].first).to include(name: "Marcus Sterling", status_key: "pos")
    expect(payload[:footfall][:connected]).to be(false)
  end

  it "excludes cancelled and refunded orders from the sales and queue totals" do
    create_order(workflow_status: :paid, business_type: :in_store)
    create_order(workflow_status: :cancelled, business_type: :in_store)
    create_order(workflow_status: :refunded, business_type: :online)

    payload = described_class.call(company: company, appointment: appointment)

    expect(payload[:orders].length).to eq(1)
    expect(payload[:kpis][:gross_sales_cents]).to eq(10_000)
    expect(payload[:kpis][:orders_to_fulfill]).to eq(0)
  end

  it "reports the previous day baseline for the sales delta" do
    create_order(workflow_status: :paid, business_type: :in_store)
    travel_to 1.day.from_now do
      payload = described_class.call(company: company, appointment: appointment)
      expect(payload[:kpis][:previous_gross_sales_cents]).to eq(10_000)
      expect(payload[:kpis][:gross_sales_delta_pct]).to eq(-100.0)
    end
  end

  it "marks an empty shelf when available units reach zero" do
    create_low_stock(quantity: 0, pending: 0)

    payload = described_class.call(company: company, appointment: appointment)

    expect(payload[:replenishments].first).to include(stage: "empty", shelf_quantity: 0)
  end

  it "returns zeroed KPIs and empty collections when the branch has no activity" do
    payload = described_class.call(company: company, appointment: appointment)

    expect(payload[:kpis]).to include(gross_sales_cents: 0, orders_to_fulfill: 0, shelf_alerts: 0, staff_on_duty: 0)
    expect(payload[:orders]).to be_empty
    expect(payload[:replenishments]).to be_empty
    expect(payload[:registers]).to be_empty
    expect(payload[:staff]).to be_empty
  end
end
