# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::Operations::StoreManager", type: :feature, js: true do
  let(:company_user) { create(:user, :company_owner) }
  let(:company) { Seed::CompanyService.new(user: company_user, country: :us, business_type: :retail).tap(&:save!) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company, name: "Downtown Flagship", code: "STORE-104") }
  let(:operation) { create(:operation, company: company, branch: branch, operation_type: :store_manager) }
  let(:store_manager_path) { "/companies/#{company.id}/operations/store_manager/#{operation.id}?branch_id=#{branch.id}" }
  let(:employee) do
    create(:employee, company: company, branch: branch, name: "Marcus Sterling").tap do |record|
      record.update!(lifecycle_status: :active, discarded_at: nil)
    end
  end
  let(:customer) { Seed::CustomerService.create(company: company, branch: branch, name: "Marcus Vance") }
  let(:delivery_customer) { Seed::CustomerService.create(company: company, branch: branch, name: "Elena Rostova") }
  let(:product) { create(:product, company: company, name: "MX Master 3S Graphite") }
  let(:warehouse) { Seed::WarehouseService.create(company: company, branch: branch, name: "WH-01 Central") }

  before do
    create_order(workflow_status: :paid, business_type: :in_store, employee: employee, customer: customer)
    create_order(workflow_status: :pending, business_type: :online, employee: employee, customer: delivery_customer)
    create_low_stock
    sign_in(owner)
  end

  def create_order(workflow_status:, business_type:, employee: nil, customer:, quantity: 2, unit_price: 50.0)
    order = Seed::OrderService.create(
      company: company,
      branch: branch,
      customer: customer,
      currency: :usd,
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

  def create_low_stock(quantity: 2)
    stock = Seed::StockService.create(
      company: company,
      warehouse: warehouse,
      branch: branch,
      product_id: product.id,
      name: "MX Master 3S Graphite",
      code: "LOGI-MX3S-GRP",
      quantity: quantity,
      pending: 0,
      discarded_at: nil
    )
    stock.update!(discarded_at: nil)
    stock
  end

  scenario "loads the live store KPIs, fulfillment queue and shelf alerts" do
    visit store_manager_path

    expect(page).to have_content("Store Fulfillment & Customer Orders Queue", wait: 10)
    expect(page).to have_content("GROSS SALES TODAY")
    expect(page).to have_content("Marcus Vance")
    expect(page).to have_content("MX Master 3S Graphite")
    expect(page).to have_content("Shelf Replenishment Requisitions")
    expect(page).to have_content("Active Register & POS Status")
    expect(page).to have_content("Marcus Sterling")
    expect(page).to have_content("On-Duty Shift Roster")
  end

  scenario "filters the fulfillment queue by channel tab" do
    visit store_manager_path
    expect(page).to have_content("Marcus Vance", wait: 10)

    find("button", text: /Local Delivery \(1\)/).click

    expect(page).to have_content("Elena Rostova", wait: 5)
    expect(page).not_to have_content("Marcus Vance")
  end

  scenario "searches the fulfillment queue by customer name" do
    visit store_manager_path
    expect(page).to have_content("Marcus Vance", wait: 10)

    fill_in "store-manager-order-search", with: "Nobody"

    expect(page).to have_content("No orders match this view.", wait: 5)
  end
end
