require "rails_helper"

RSpec.describe Events::CreateOrderService do
  let(:company) { create(:company) }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "events") }
  let(:branch) { create(:branch, company: company) }
  let(:event) do
    create(:event, company: company, branch: branch, category: category,
      start_at: 2.hours.from_now, end_at: 3.hours.from_now, workflow_status: :completed)
  end

  def stock_with_units(units)
    warehouse = create(:warehouse, company: company)
    product = create(:product, company: company)
    stock = Seed::StockService.create(warehouse: warehouse, product_id: product.id, company: company, branch: warehouse.branch)
    stock.update_columns(quantity: units, pending: 0)
    stock
  end

  before do
    create(:event_config, company: company, category: category, create_order_on_complete: true)
  end

  describe "with stock and service lines" do
    it "creates a pending order with snapshots and links it" do
      stock = stock_with_units(10)
      EventStockAppointment.create!(company: company, event: event, stock: stock, quantity: 2)
      service = Seed::ServiceService.create(company: company, branch: branch)
      EventServiceAppointment.create!(company: company, event: event, service: service)
      customer = create(:customer, company: company)
      CustomerEventAppointment.create!(company: company, event: event, customer: customer)

      result = described_class.call(event: event)

      expect(result[:success]).to be(true)
      order = result[:order]
      expect(order.workflow_status).to eq("pending")
      expect(order.customer_id).to eq(customer.id)
      product_line = order.order_product_appointments.first
      expect(product_line.product_id).to eq(stock.product_id)
      expect(product_line.quantity).to eq(2)
      expect(product_line.unit_price.to_f).to eq(stock.product.price.to_f)
      service_line = order.order_service_appointments.first
      expect(service_line.service_id).to eq(service.id)
      expect(service_line.unit_price.to_f).to eq(service.price.to_f)
      expect(EventOrderAppointment.find_by(event: event, order: order)).to be_present
    end

    it "creates a walk-in customer when the event has none" do
      stock = stock_with_units(10)
      EventStockAppointment.create!(company: company, event: event, stock: stock, quantity: 1)

      result = described_class.call(event: event)

      expect(result[:success]).to be(true)
      expect(result[:order].customer).to be_present
    end
  end

  describe "idempotency" do
    it "does not create a second order" do
      stock = stock_with_units(10)
      EventStockAppointment.create!(company: company, event: event, stock: stock, quantity: 1)

      first = described_class.call(event: event)
      second = described_class.call(event: event)

      expect(second[:success]).to be(true)
      expect(second[:order].id).to eq(first[:order].id)
      expect(EventOrderAppointment.where(event: event).count).to eq(1)
    end
  end

  describe "when the category does not create orders" do
    it "creates nothing" do
      EventConfig.find_by(company: company, category: category).update!(create_order_on_complete: false)
      stock = stock_with_units(10)
      EventStockAppointment.create!(company: company, event: event, stock: stock, quantity: 1)

      result = described_class.call(event: event)

      expect(result[:success]).to be(false)
      expect(EventOrderAppointment.where(event: event).count).to eq(0)
    end
  end

  describe "with no lines" do
    it "creates nothing" do
      result = described_class.call(event: event)

      expect(result[:success]).to be(false)
      expect(EventOrderAppointment.where(event: event).count).to eq(0)
    end
  end
end
