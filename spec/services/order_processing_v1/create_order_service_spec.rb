# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderProcessingV1::CreateOrderService do
  describe ".call" do
    subject(:result) do
      described_class.call(company: company, branch: branch, items: items, customer: customer)
    end

    let(:company) { create(:company) }
    let(:branch) { create(:branch, company: company) }
    let(:product) { create(:product, company: company, branch: branch, price_cents: 5_000) }
    let(:warehouse) { create(:warehouse, company: company, branch: branch) }
    let!(:stock) do
      category = product.category
      Stock.create!(
        company: company, warehouse: warehouse, product: product,
        quantity: 10, pending: 0, category: category,
        property_mapping: category.default_property_mapping
      ).tap { |record| record.send(:sync_available_counter) }
    end
    let(:customer) { create(:customer, company: company, branch: branch) }
    let(:items) { [ { product_id: product.id, quantity: 2 } ] }

    it "creates an Order with workflow_status pending" do
      expect { result }.to change(Order, :count).by(1)
      expect(Order.last.workflow_status).to eq("pending")
    end

    it "prices the line from the product record, not the request" do
      described_class.call(
        company: company, branch: branch,
        items: [ { product_id: product.id, quantity: 2, unit_price: 1 } ],
        customer: customer
      )

      line = OrderProductAppointment.last
      expect(line.unit_price.to_f).to eq(50.0)
      expect(line.total_price.to_f).to eq(100.0)
      expect(line.stock_id).to eq(stock.id)
    end

    it "returns cents and the company currency" do
      expect(result[:order_id]).to be_present
      expect(result[:currency]).to eq(company.currency)
      expect(result[:subtotal_cents]).to eq(10_000)
      expect(result[:tax_cents]).to eq(0)
      expect(result[:total_cents]).to eq(10_000)
      expect(result[:items]).to eq([
        { kind: "product", id: product.id, quantity: 2, unit_price_cents: 5_000, total_cents: 10_000, tax: nil }
      ])
    end

    it "snapshots the product tax on the line and the order" do
      code = create(:tax_code, company: company, name: "VAT", rate_bp: 1_000)
      product.update!(tax_code: code)

      result = described_class.call(company: company, branch: branch, items: items, customer: customer)

      line = OrderProductAppointment.last
      expect(line.tax_code_id).to eq(code.id)
      expect(line.tax_name).to eq("VAT")
      expect(line.tax_rate_bp).to eq(1_000)
      expect(line.tax_inclusive).to be(false)
      expect(line.taxable_cents).to eq(10_000)
      expect(line.tax_cents).to eq(1_000)
      expect(Order.last.tax_cents).to eq(1_000)
      expect(Order.last.total_cents).to eq(11_000)
      expect(result[:tax_lines].first).to include(name: "VAT", tax_cents: 1_000)
      expect(result[:items].first[:tax]).to include(id: code.id, name: "VAT", rate_bp: 1_000)
    end

    it "uses the company currency instead of hardcoding USD" do
      # Company derives currency from country on save, so move the country too.
      company.update!(country: :vn, currency: :vnd)
      product.update!(price_cents: 50_000)

      result = described_class.call(
        company: company, branch: branch,
        items: [ { product_id: product.id, quantity: 1 } ], customer: customer
      )

      expect(result[:currency]).to eq("vnd")
      expect(result[:subtotal_cents]).to eq(50_000)
      expect(Order.last.currency).to eq("vnd")
    end

    context "employee attribution" do
      let(:employee) { create(:employee, company: company) }

      it "attributes the order to the given employee" do
        described_class.call(company: company, branch: branch, items: items, customer: customer, employee: employee)

        expect(Order.last.employee).to eq(employee)
      end

      it "leaves the employee blank when no employee is given" do
        described_class.call(company: company, branch: branch, items: items, customer: customer)

        expect(Order.last.employee).to be_nil
      end
    end

    context "with multiple items" do
      let(:product2) { create(:product, company: company, branch: branch, price_cents: 1_000) }
      let!(:stock2) do
        category = product2.category
        Stock.create!(
          company: company, warehouse: warehouse, product: product2,
          quantity: 5, pending: 0, category: category,
          property_mapping: category.default_property_mapping
        ).tap { |record| record.send(:sync_available_counter) }
      end
      let(:items) do
        [
          { product_id: product.id, quantity: 2 },
          { product_id: product2.id, quantity: 3 }
        ]
      end

      it "creates an appointment for each item" do
        expect { result }.to change(OrderProductAppointment, :count).by(2)
      end

      it "returns the combined cents total" do
        expect(result[:subtotal_cents]).to eq(13_000)
      end
    end

    it "rejects a product from another company" do
      other_product = create(:product, company: create(:company))

      expect {
        described_class.call(company: company, branch: branch,
          items: [ { product_id: other_product.id, quantity: 1 } ], customer: customer)
      }.to raise_error(OrderProcessingV1::InvalidOrderItemError, /not found/)
      expect(Order.count).to eq(0)
    end

    it "rejects a product that is not stocked in the branch" do
      other_branch = create(:branch, company: company)
      other_warehouse = create(:warehouse, company: company, branch: other_branch)
      stock.update!(warehouse: other_warehouse)

      expect {
        described_class.call(company: company, branch: branch,
          items: [ { product_id: product.id, quantity: 1 } ], customer: customer)
      }.to raise_error(OrderProcessingV1::InsufficientStockError, /not stocked/)
      expect(Order.count).to eq(0)
    end

    it "rejects a product with no configured price" do
      product.update_columns(price_cents: nil)

      expect {
        described_class.call(company: company, branch: branch,
          items: [ { product_id: product.id, quantity: 1 } ], customer: customer)
      }.to raise_error(OrderProcessingV1::InvalidOrderItemError, /price/i)
      expect(Order.count).to eq(0)
    end

    it "rejects a quantity below one" do
      expect {
        described_class.call(company: company, branch: branch,
          items: [ { product_id: product.id, quantity: 0 } ], customer: customer)
      }.to raise_error(OrderProcessingV1::InvalidOrderItemError, /quantity/i)
      expect(Order.count).to eq(0)
    end
  end
end
