# Order Processing V1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build backend order processing pipeline: checkout (availability check + order creation) → pay (Redis stock reserve + payment record + async ledger/balance finalization).

**Architecture:** 7 services in `OrderProcessingV1` module orchestrated by `Companies::OrderProcessing::V1Controller`. Redis first layer. Async Solid Queue for heavy DB writes. Raw SQL for stock balances.

**Tech Stack:** Rails 7+, PostgreSQL, Redis/Kredis, Solid Queue

---

### File Structure

```
Create:
  app/services/order_processing_v1.rb
  app/services/order_processing_v1/check_availability_service.rb
  app/services/order_processing_v1/create_order_service.rb
  app/services/order_processing_v1/reserve_stock_service.rb
  app/services/order_processing_v1/process_payment_service.rb
  app/services/order_processing_v1/write_stock_ledger_service.rb
  app/services/order_processing_v1/update_stock_balances_service.rb
  app/services/order_processing_v1/finalize_order_service.rb
  app/jobs/order_processing_v1.rb
  app/jobs/order_processing_v1/finalize_job.rb
  app/controllers/companies/order_processing/v1_controller.rb

Modify:
  app/models/stock.rb
  config/routes.rb

Test:
  spec/services/order_processing_v1/check_availability_service_spec.rb
  spec/services/order_processing_v1/create_order_service_spec.rb
  spec/services/order_processing_v1/reserve_stock_service_spec.rb
  spec/services/order_processing_v1/process_payment_service_spec.rb
  spec/services/order_processing_v1/write_stock_ledger_service_spec.rb
  spec/services/order_processing_v1/update_stock_balances_service_spec.rb
  spec/services/order_processing_v1/finalize_order_service_spec.rb
  spec/jobs/order_processing_v1/finalize_job_spec.rb
  spec/requests/companies/order_processing/v1_controller_spec.rb
```

---

### Task 1: Module Setup + Stock Model + Redis Counter

**Files:**
- Create: `app/services/order_processing_v1.rb`
- Create: `app/jobs/order_processing_v1.rb`
- Modify: `app/models/stock.rb`

- [ ] **Step 1: Create module root files**

`app/services/order_processing_v1.rb`:
```ruby
module OrderProcessingV1
  class InsufficientStockError < StandardError; end
end
```

`app/jobs/order_processing_v1.rb`:
```ruby
module OrderProcessingV1
end
```

- [ ] **Step 2: Add kredis counter to Stock model**

After existing enums, add:
```ruby
kredis_integer :available_counter, key: ->(s) { "stock:#{s.id}:available" }
```

Add after_save callback:
```ruby
after_save :sync_available_counter, if: -> { saved_change_to_quantity? || saved_change_to_reserved_quantity? }

private

def sync_available_counter
  available_counter.value = [quantity - reserved_quantity, 0].max
end
```

- [ ] **Step 3: Verify**

Run: `bin/rails r "puts Stock.first.available_counter.value"`

- [ ] **Step 4: Commit**

---

### Task 2: CheckAvailabilityService

**Files:**
- Create: `app/services/order_processing_v1/check_availability_service.rb`
- Create: `spec/services/order_processing_v1/check_availability_service_spec.rb`

- [ ] **Step 1: Write the failing test**

```ruby
require "rails_helper"

RSpec.describe OrderProcessingV1::CheckAvailabilityService do
  describe ".call" do
    subject(:result) { described_class.call(items: items) }

    let(:company) { create(:company) }
    let(:product) { create(:product, company: company) }
    let(:warehouse) { create(:warehouse, company: company) }
    let(:stock) { create(:stock, company: company, product: product, warehouse: warehouse, quantity: 10, reserved_quantity: 0) }
    let(:items) { [{ stock_id: stock.id, quantity: 3 }] }

    before { stock.sync_available_counter }

    context "when all items are available" do
      it "returns available: true" do
        expect(result).to eq({ available: true })
      end
    end

    context "when an item has insufficient stock" do
      let(:items) { [{ stock_id: stock.id, quantity: 20 }] }

      it "returns available: false with the failed item" do
        expect(result[:available]).to be false
        expect(result[:failed_item]).to eq(stock.id)
      end
    end
  end
end
```

- [ ] **Step 2: Implement**

```ruby
module OrderProcessingV1
  class CheckAvailabilityService
    def self.call(items:)
      items.each do |item|
        stock = Stock.find(item[:stock_id])
        available = stock.available_counter.value
        return { available: false, failed_item: item[:stock_id] } if available < item[:quantity]
      end
      { available: true }
    end
  end
end
```

- [ ] **Step 3: Run tests — verify pass**
- [ ] **Step 4: Commit**

---

### Task 3: CreateOrderService

**Files:**
- Create: `app/services/order_processing_v1/create_order_service.rb`
- Create: `spec/services/order_processing_v1/create_order_service_spec.rb`

- [ ] **Step 1: Write failing test**

```ruby
require "rails_helper"

RSpec.describe OrderProcessingV1::CreateOrderService do
  describe ".call" do
    subject(:result) { described_class.call(company: company, branch: branch, items: items, customer: customer) }

    let(:company) { create(:company) }
    let(:branch) { create(:branch, company: company) }
    let(:product) { create(:product, company: company, branch: branch) }
    let(:warehouse) { create(:warehouse, company: company) }
    let!(:stock) { create(:stock, company: company, product: product, warehouse: warehouse, quantity: 10) }
    let(:customer) { create(:customer, company: company, branch: branch) }
    let(:items) do
      [{ stock_id: stock.id, product_id: product.id, quantity: 2, unit_price: 50.00 }]
    end

    it "creates an Order with workflow_status pending" do
      expect { result }.to change(Order, :count).by(1)
      expect(Order.last.workflow_status).to eq("pending")
    end

    it "creates OrderAppointments for each item" do
      expect { result }.to change(OrderAppointment, :count).by(1)
      oa = OrderAppointment.last
      expect(oa.quantity).to eq(2)
      expect(oa.appoint_to).to eq(product)
    end

    it "returns order_id and total_price" do
      expect(result[:order_id]).to be_present
      expect(result[:total_price]).to eq(100.00)
    end
  end
end
```

- [ ] **Step 2: Implement**

```ruby
module OrderProcessingV1
  class CreateOrderService
    def self.call(company:, branch:, items:, customer: nil)
      total_price = items.sum { |i| i[:quantity].to_i * i[:unit_price].to_f }

      order = Order.create!(
        company: company,
        branch: branch,
        customer: customer,
        name: "POS Order #{Time.current.to_i}",
        workflow_status: :pending,
        currency_code: :usd,
        business_type: :in_store
      )

      order_appointments = items.map do |item|
        product = Product.find(item[:product_id])
        {
          company_id: company.id,
          order_id: order.id,
          appoint_to_type: "Product",
          appoint_to_id: item[:product_id],
          quantity: item[:quantity],
          unit_price: item[:unit_price],
          total_price: item[:quantity].to_i * item[:unit_price].to_f,
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      OrderAppointment.insert_all!(order_appointments)

      { order_id: order.id, total_price: total_price }
    end
  end
end
```

- [ ] **Step 3: Run tests — verify pass**
- [ ] **Step 4: Commit**

---

### Task 4: ReserveStockService

**Files:**
- Create: `app/services/order_processing_v1/reserve_stock_service.rb`
- Create: `spec/services/order_processing_v1/reserve_stock_service_spec.rb`

- [ ] **Step 1: Write failing test**

```ruby
require "rails_helper"

RSpec.describe OrderProcessingV1::ReserveStockService do
  describe ".call" do
    let(:company) { create(:company) }
    let(:product) { create(:product, company: company) }
    let(:warehouse) { create(:warehouse, company: company) }
    let(:stock) { create(:stock, company: company, product: product, warehouse: warehouse, quantity: 5, reserved_quantity: 0) }
    let(:items) { [{ stock_id: stock.id, quantity: 2 }] }

    before { stock.sync_available_counter }

    context "when stock is sufficient" do
      it "decrements the Redis counter and returns success" do
        result = described_class.call(items: items)
        expect(result[:success]).to be true
        expect(stock.available_counter.value).to eq(3)
      end
    end

    context "when stock runs out" do
      let(:items) { [{ stock_id: stock.id, quantity: 10 }] }

      it "rolls back and raises InsufficientStockError" do
        expect { described_class.call(items: items) }
          .to raise_error(OrderProcessingV1::InsufficientStockError)
        expect(stock.available_counter.value).to eq(5)
      end
    end
  end
end
```

- [ ] **Step 2: Implement**

```ruby
module OrderProcessingV1
  class ReserveStockService
    def self.call(items:)
      redis = Kredis.redis
      results = redis.multi do |multi|
        items.each do |item|
          multi.decrby("stock:#{item[:stock_id]}:available", item[:quantity])
        end
      end

      items.each_with_index do |item, idx|
        next unless results[idx].to_i < 0

        redis.multi do |multi|
          items.each_with_index do |rollback_item, ridx|
            next if ridx > idx
            multi.incrby("stock:#{rollback_item[:stock_id]}:available", rollback_item[:quantity])
          end
        end

        raise InsufficientStockError, "Insufficient stock for item #{item[:stock_id]}"
      end

      { success: true }
    end
  end
end
```

- [ ] **Step 3: Run tests — verify pass**
- [ ] **Step 4: Commit**

---

### Task 5: ProcessPaymentService

**Files:**
- Create: `app/services/order_processing_v1/process_payment_service.rb`
- Create: `spec/services/order_processing_v1/process_payment_service_spec.rb`

- [ ] **Step 1: Write failing test**

```ruby
require "rails_helper"

RSpec.describe OrderProcessingV1::ProcessPaymentService do
  describe ".call" do
    subject(:result) { described_class.call(order: order) }

    let(:company) { create(:company) }
    let(:branch) { create(:branch, company: company) }
    let(:category) { create(:category, company: company, resource_name: "invoices") }
    let(:order) { create(:order, company: company, branch: branch, workflow_status: :pending) }

    it "creates an Invoice" do
      expect { result }.to change(Invoice, :count).by(1)
    end

    it "creates a Payment" do
      expect { result }.to change(Payment, :count).by(1)
    end

    it "sets Order workflow_status to paid" do
      result
      expect(order.reload.workflow_status).to eq("paid")
    end

    it "returns payment_id" do
      expect(result[:payment_id]).to be_present
    end
  end
end
```

- [ ] **Step 2: Implement**

```ruby
module OrderProcessingV1
  class ProcessPaymentService
    def self.call(order:)
      invoice = Invoice.create!(
        company_id: order.company_id,
        branch_id: order.branch_id,
        order_id: order.id,
        name: "Invoice for Order #{order.id}",
        code: "INV-#{Time.current.to_i}-#{SecureRandom.hex(3).upcase}",
        total_price: order.total_price || order.order_appointments.sum(:total_price),
        currency_code: order.currency_code,
        workflow_status: :paid
      )

      payment = Payment.create!(
        company_id: order.company_id,
        branch_id: order.branch_id,
        invoice_id: invoice.id,
        currency_code: order.currency_code,
        workflow_status: :completed,
        business_type: :standard_payment
      )

      order.update!(workflow_status: :paid)

      { payment_id: payment.id }
    end
  end
end
```

- [ ] **Step 3: Run tests — verify pass**
- [ ] **Step 4: Commit**

---

### Task 6: WriteStockLedgerService + UpdateStockBalancesService

**Files:**
- Create: `app/services/order_processing_v1/write_stock_ledger_service.rb`
- Create: `app/services/order_processing_v1/update_stock_balances_service.rb`
- Create: `spec/services/order_processing_v1/write_stock_ledger_service_spec.rb`
- Create: `spec/services/order_processing_v1/update_stock_balances_service_spec.rb`

- [ ] **Step 1: Write test for WriteStockLedgerService**

```ruby
require "rails_helper"

RSpec.describe OrderProcessingV1::WriteStockLedgerService do
  describe ".call" do
    let(:company) { create(:company) }
    let(:branch) { create(:branch, company: company) }
    let(:product) { create(:product, company: company, branch: branch) }
    let(:warehouse) { create(:warehouse, company: company) }
    let!(:stock) { create(:stock, company: company, product: product, warehouse: warehouse, quantity: 10) }
    let(:order) { create(:order, company: company, branch: branch, workflow_status: :paid) }
    let!(:oa) { create(:order_appointment, order: order, company: company, appoint_to: product, quantity: 2, unit_price: 50, total_price: 100) }

    it "creates StockTransaction records" do
      expect { described_class.call(order: order) }.to change(StockTransaction, :count).by(1)
      trx = StockTransaction.last
      expect(trx.direction).to eq("remove")
      expect(trx.transaction_type).to eq("export")
      expect(trx.quantity).to eq(2)
    end

    it "returns count of transactions created" do
      result = described_class.call(order: order)
      expect(result[:count]).to eq(1)
    end
  end
end
```

- [ ] **Step 2: Implement WriteStockLedgerService**

```ruby
module OrderProcessingV1
  class WriteStockLedgerService
    def self.call(order:)
      rows = order.order_appointments.map do |oa|
        product = oa.appoint_to
        stock = Stock.find_by!(company_id: order.company_id, product_id: product.id)
        {
          company_id: order.company_id,
          branch_id: order.branch_id,
          warehouse_id: stock.warehouse_id,
          product_id: product.id,
          category_id: stock.category_id,
          property_mapping_id: stock.property_mapping_id,
          quantity: oa.quantity,
          direction: StockTransaction.directions[:remove],
          transaction_type: StockTransaction.transaction_types[:export],
          appoint_for_type: "Order",
          appoint_for_id: order.id,
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      StockTransaction.insert_all!(rows) if rows.any?
      { count: rows.size }
    end
  end
end
```

- [ ] **Step 3: Write test for UpdateStockBalancesService**

```ruby
require "rails_helper"

RSpec.describe OrderProcessingV1::UpdateStockBalancesService do
  describe ".call" do
    let(:company) { create(:company) }
    let(:branch) { create(:branch, company: company) }
    let(:product) { create(:product, company: company, branch: branch) }
    let(:warehouse) { create(:warehouse, company: company) }
    let!(:stock) { create(:stock, company: company, product: product, warehouse: warehouse, quantity: 10, reserved_quantity: 5) }
    let(:order) { create(:order, company: company, branch: branch, workflow_status: :paid) }
    let!(:oa) { create(:order_appointment, order: order, company: company, appoint_to: product, quantity: 2, unit_price: 50, total_price: 100) }

    it "reduces quantity and reserved_quantity" do
      described_class.call(order: order)
      stock.reload
      expect(stock.quantity).to eq(8)
      expect(stock.reserved_quantity).to eq(3)
    end

    it "returns updated stock ids" do
      result = described_class.call(order: order)
      expect(result[:updated]).to include(stock.id)
    end
  end
end
```

- [ ] **Step 4: Implement UpdateStockBalancesService**

```ruby
module OrderProcessingV1
  class UpdateStockBalancesService
    def self.call(order:)
      updated = []
      order.order_appointments.each do |oa|
        product = oa.appoint_to
        stock = Stock.find_by!(company_id: order.company_id, product_id: product.id)

        Stock.where(id: stock.id).update_all(
          ["quantity = quantity - ?, reserved_quantity = reserved_quantity - ?", oa.quantity, oa.quantity]
        )

        updated << stock.id
      end

      { updated: updated }
    end
  end
end
```

- [ ] **Step 5: Run tests — verify pass**
- [ ] **Step 6: Commit**

---

### Task 7: FinalizeOrderService

**Files:**
- Create: `app/services/order_processing_v1/finalize_order_service.rb`
- Create: `spec/services/order_processing_v1/finalize_order_service_spec.rb`

- [ ] **Step 1: Write failing test**

```ruby
require "rails_helper"

RSpec.describe OrderProcessingV1::FinalizeOrderService do
  describe ".call" do
    let(:company) { create(:company) }
    let(:branch) { create(:branch, company: company) }
    let(:product) { create(:product, company: company, branch: branch) }
    let(:warehouse) { create(:warehouse, company: company) }
    let!(:stock) { create(:stock, company: company, product: product, warehouse: warehouse, quantity: 10) }
    let(:order) { create(:order, company: company, branch: branch, workflow_status: :paid) }
    let!(:oa) { create(:order_appointment, order: order, company: company, appoint_to: product, quantity: 2, unit_price: 50, total_price: 100) }

    it "creates StockExport records for each item" do
      expect { described_class.call(order: order) }.to change(StockExport, :count).by(1)
      export = StockExport.last
      expect(export.business_type).to eq("sale")
      expect(export.quantity).to eq(2)
    end
  end
end
```

- [ ] **Step 2: Implement**

```ruby
module OrderProcessingV1
  class FinalizeOrderService
    def self.call(order:)
      export_ids = []
      order.order_appointments.each do |oa|
        product = oa.appoint_to
        stock = Stock.find_by!(company_id: order.company_id, product_id: product.id)

        export = StockExport.create!(
          company_id: order.company_id,
          branch_id: order.branch_id,
          warehouse_id: stock.warehouse_id,
          product_id: product.id,
          category_id: stock.category_id,
          property_mapping_id: stock.property_mapping_id,
          quantity: oa.quantity,
          business_type: :sale,
          code: "EXP-#{Time.current.to_i}-#{SecureRandom.hex(3).upcase}",
          workflow_status: :completed
        )

        export_ids << export.id
      end

      { export_ids: export_ids }
    end
  end
end
```

- [ ] **Step 3: Run tests — verify pass**
- [ ] **Step 4: Commit**

---

### Task 8: FinalizeJob

**Files:**
- Create: `app/jobs/order_processing_v1/finalize_job.rb`
- Create: `spec/jobs/order_processing_v1/finalize_job_spec.rb`

- [ ] **Step 1: Write failing test**

```ruby
require "rails_helper"

RSpec.describe OrderProcessingV1::FinalizeJob do
  describe "#perform" do
    let(:company) { create(:company) }
    let(:branch) { create(:branch, company: company) }
    let(:product) { create(:product, company: company, branch: branch) }
    let(:warehouse) { create(:warehouse, company: company) }
    let!(:stock) { create(:stock, company: company, product: product, warehouse: warehouse, quantity: 10, reserved_quantity: 5) }
    let(:order) { create(:order, company: company, branch: branch, workflow_status: :paid) }
    let!(:oa) { create(:order_appointment, order: order, company: company, appoint_to: product, quantity: 2, unit_price: 50, total_price: 100) }

    it "creates StockTransaction, updates stock, and creates StockExport" do
      expect {
        described_class.perform_now(order.id)
      }.to change(StockTransaction, :count).by(1)
       .and change(StockExport, :count).by(1)

      stock.reload
      expect(stock.quantity).to eq(8)
      expect(stock.reserved_quantity).to eq(3)
    end

    it "is idempotent" do
      described_class.perform_now(order.id)
      expect {
        described_class.perform_now(order.id)
      }.to_not change(StockTransaction, :count)
    end
  end
end
```

- [ ] **Step 2: Implement**

```ruby
module OrderProcessingV1
  class FinalizeJob < ApplicationJob
    queue_as :order_finalization

    def perform(order_id)
      order = Order.find(order_id)
      return if order.workflow_status != "paid"
      return if StockExport.where(
        company_id: order.company_id,
        appoint_for_type: "Order",
        appoint_for_id: order.id
      ).exists?

      ActiveRecord::Base.transaction do
        WriteStockLedgerService.call(order: order)
        UpdateStockBalancesService.call(order: order)
        FinalizeOrderService.call(order: order)
      end
    end
  end
end
```

- [ ] **Step 3: Run tests — verify pass**
- [ ] **Step 4: Commit**

---

### Task 9: V1Controller + Routes

**Files:**
- Create: `app/controllers/companies/order_processing/v1_controller.rb`
- Modify: `config/routes.rb`
- Create: `spec/requests/companies/order_processing/v1_controller_spec.rb`

- [ ] **Step 1: Write request spec**

```ruby
require "rails_helper"

RSpec.describe "Companies::OrderProcessing::V1", type: :request do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:product) { create(:product, company: company, branch: branch) }
  let(:warehouse) { create(:warehouse, company: company) }
  let!(:stock) { create(:stock, company: company, product: product, warehouse: warehouse, quantity: 10, reserved_quantity: 0) }
  let(:headers) { { "ACCEPT" => "application/json" } }

  before { stock.sync_available_counter }

  describe "POST /companies/:id/order_processing/v1/checkout" do
    let(:params) do
      {
        branch_id: branch.id,
        items: [
          { stock_id: stock.id, product_id: product.id, quantity: 2, unit_price: 50.00 }
        ]
      }
    end

    it "returns 201 with order_id and total_price" do
      post "/companies/#{company.id}/order_processing/v1/checkout", params: params, headers: headers
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["order_id"]).to be_present
      expect(body["total_price"]).to eq(100.0)
    end

    context "when stock insufficient" do
      let(:params) do
        { branch_id: branch.id, items: [{ stock_id: stock.id, product_id: product.id, quantity: 20, unit_price: 50.00 }] }
      end

      it "returns 422" do
        post "/companies/#{company.id}/order_processing/v1/checkout", params: params, headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "POST /companies/:id/order_processing/v1/pay" do
    let(:order) { create(:order, company: company, branch: branch, workflow_status: :pending) }
    let!(:oa) { create(:order_appointment, order: order, company: company, appoint_to: product, quantity: 2, unit_price: 50, total_price: 100) }

    it "returns 200 with status paid" do
      post "/companies/#{company.id}/order_processing/v1/pay", params: { order_id: order.id }, headers: headers
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("paid")
      expect(body["order_id"]).to eq(order.id)
      expect(body["payment_id"]).to be_present
    end

    it "transitions order to paid" do
      expect {
        post "/companies/#{company.id}/order_processing/v1/pay", params: { order_id: order.id }, headers: headers
      }.to change { order.reload.workflow_status }.from("pending").to("paid")
    end
  end
end
```

- [ ] **Step 2: Add routes**

```ruby
# Inside resources :companies do ... scope module: :companies do ... end
scope path: 'order_processing/v1', controller: 'order_processing/v1' do
  post :checkout
  post :pay
end
```

- [ ] **Step 3: Implement controller**

```ruby
class Companies::OrderProcessing::V1Controller < Companies::ApplicationController
  def checkout
    result = OrderProcessingV1::CheckAvailabilityService.call(items: checkout_params[:items])

    unless result[:available]
      render json: { error: "Insufficient stock", failed_item: result[:failed_item] }, status: :unprocessable_entity
      return
    end

    order_result = OrderProcessingV1::CreateOrderService.call(
      company: current_company,
      branch: current_company.branches.find(checkout_params[:branch_id]),
      items: checkout_params[:items],
      customer: checkout_params[:customer_id] ? current_company.customers.find_by(id: checkout_params[:customer_id]) : nil
    )

    render json: order_result, status: :created
  end

  def pay
    order = current_company.orders.find(params[:order_id])

    items = order.order_appointments.map do |oa|
      product = oa.appoint_to
      stock = current_company.stocks.find_by!(product_id: product.id)
      { stock_id: stock.id, quantity: oa.quantity }
    end

    OrderProcessingV1::ReserveStockService.call(items: items)

    payment_result = OrderProcessingV1::ProcessPaymentService.call(order: order)

    OrderProcessingV1::FinalizeJob.perform_later(order.id)

    render json: {
      status: "paid",
      order_id: order.id,
      payment_id: payment_result[:payment_id]
    }
  end

  private

  def checkout_params
    params.permit(:branch_id, :customer_id, items: [:stock_id, :product_id, :quantity, :unit_price])
  end
end
```

- [ ] **Step 4: Run rubocop**

Run: `bin/rubocop --autocorrect-all`

- [ ] **Step 5: Run tests — verify pass**

Run: `bundle exec rspec spec/requests/companies/order_processing/v1_controller_spec.rb`

- [ ] **Step 6: Commit**
