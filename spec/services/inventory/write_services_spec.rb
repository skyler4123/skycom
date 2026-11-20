# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Inventory write services", type: :service do
  let(:company_user) { create(:user, :company_owner) }
  let(:company) { Seed::CompanyService.new(user: company_user, country: :us, business_type: :retail).tap(&:save!) }
  let(:branch) { create(:branch, company: company, name: "Grocery VN") }
  let(:warehouse) { Seed::WarehouseService.create(company: company, branch: branch, name: "Branch 1 Warehouse", code: "WH-01") }
  let(:destination) { Seed::WarehouseService.create(company: company, branch: branch, name: "Branch 2 Warehouse", code: "WH-02") }
  let(:employee) { company.employees.find_by!(user: company_user) }
  let(:product) { create(:product, company: company, name: "Product 1", code: "SKU-001", business_type: :physical) }

  def create_stock(target_warehouse: warehouse, quantity: 20, pending: 0, record_product: product)
    stock = Seed::StockService.create(
      company: company, warehouse: target_warehouse, branch: branch,
      product_id: record_product.id, name: record_product.name, code: record_product.code,
      quantity: quantity, pending: pending, discarded_at: nil
    )
    stock.update!(discarded_at: nil, property_string_1: "A-01")
    stock
  end

  before do
    warehouse
    destination
  end

  describe Inventory::ReceiveService do
    it "posts a receipt, increases on hand and records the location" do
      stock = create_stock(quantity: 10)

      result = described_class.post(
        company: company, warehouse: warehouse, employee: employee,
        stock_id: stock.id, quantity: 10, location: "B-02"
      )

      expect(stock.reload.quantity).to eq(20)
      expect(stock.property_string_1).to eq("B-02")
      expect(result[:message]).to include("Received 10", "on hand 10 → 20")
      import = company.stock_imports.find(result[:import_id])
      expect(import.workflow_status).to eq("received")
      expect(import.quantity).to eq(10)
      expect(import.stock_import_stock_appointments.first.quantity).to eq(10)
    end

    it "rejects a service item" do
      service_product = create(:product, company: company, name: "Installation", business_type: :service_based)
      stock = create_stock(record_product: service_product, quantity: 1)

      expect {
        described_class.post(company: company, warehouse: warehouse, employee: employee, stock_id: stock.id, quantity: 1)
      }.to raise_error(Inventory::Error, "Service items cannot be stocked.")
      expect(stock.reload.quantity).to eq(1)
    end

    it "rejects a non-positive or decimal quantity" do
      stock = create_stock(quantity: 10)

      expect {
        described_class.post(company: company, warehouse: warehouse, employee: employee, stock_id: stock.id, quantity: 0)
      }.to raise_error(Inventory::Error, /greater than 0/)
      expect {
        described_class.post(company: company, warehouse: warehouse, employee: employee, stock_id: stock.id, quantity: "1.5")
      }.to raise_error(Inventory::Error, /greater than 0/)
      expect(stock.reload.quantity).to eq(10)
    end

    it "rejects a stock row from another company" do
      other_company = create(:company)
      other_branch = create(:branch, company: other_company)
      other_warehouse = Seed::WarehouseService.create(company: other_company, branch: other_branch)
      other_product = create(:product, company: other_company)
      other_stock = Seed::StockService.create(
        company: other_company, warehouse: other_warehouse, branch: other_branch,
        product_id: other_product.id, name: other_product.name, code: other_product.code,
        quantity: 5, pending: 0, discarded_at: nil
      )

      expect {
        described_class.post(company: company, warehouse: warehouse, employee: employee, stock_id: other_stock.id, quantity: 1)
      }.to raise_error(Inventory::Error, "Item not found in this warehouse.")
      expect(other_stock.reload.quantity).to eq(5)
    end

    it "resumes an open import without lines" do
      stock = create_stock(quantity: 10)
      import = create(:stock_import, company: company, warehouse: warehouse, product: product,
        quantity: 0, workflow_status: :draft, code: "IMP-OPEN-1")

      result = described_class.post_import(
        company: company, warehouse: warehouse, employee: employee,
        import_id: import.id, stock_id: stock.id, quantity: 4
      )

      expect(stock.reload.quantity).to eq(14)
      expect(import.reload.workflow_status).to eq("received")
      expect(result[:message]).to include("Received 4")
    end

    it "resumes an open import that already has lines" do
      stock = create_stock(quantity: 10)
      import = create(:stock_import, company: company, warehouse: warehouse, product: product,
        quantity: 3, workflow_status: :draft, code: "IMP-OPEN-2")
      import.stock_import_stock_appointments.create!(company: company, stock: stock, quantity: 3)

      described_class.post_import(company: company, warehouse: warehouse, employee: employee, import_id: import.id)

      expect(stock.reload.quantity).to eq(13)
      expect(import.reload.workflow_status).to eq("received")
    end
  end

  describe Inventory::TransferService do
    it "initiates a transfer, holds the source and receives it at the destination" do
      stock = create_stock(quantity: 20)

      result = described_class.transfer(
        company: company, warehouse: warehouse, employee: employee,
        stock_id: stock.id, quantity: 4, destination_warehouse_id: destination.id
      )

      stock.reload
      expect(stock.pending).to eq(4)
      expect(stock.quantity).to eq(20)
      expect(stock.quantity - stock.pending).to eq(16)

      transfer = company.stock_transfers.find(result[:transfer_id])
      expect(transfer.workflow_status).to eq("initiated")
      expect(transfer.destination_warehouse).to eq(destination)

      described_class.receive(company: company, warehouse: destination, employee: employee, transfer_id: transfer.id)

      stock.reload
      expect(stock.quantity).to eq(16)
      expect(stock.pending).to eq(0)

      destination_stock = company.stocks.find_by!(warehouse: destination, product_id: product.id)
      expect(destination_stock.quantity).to eq(4)
      expect(transfer.reload.workflow_status).to eq("received")
    end

    it "rejects a quantity above available" do
      stock = create_stock(quantity: 5, pending: 2)

      expect {
        described_class.transfer(
          company: company, warehouse: warehouse, employee: employee,
          stock_id: stock.id, quantity: 4, destination_warehouse_id: destination.id
        )
      }.to raise_error(Inventory::Error, "Only 3 available in Branch 1 Warehouse.")
      expect(company.stock_transfers.count).to eq(0)
    end

    it "rejects the same source and destination" do
      stock = create_stock(quantity: 5)

      expect {
        described_class.transfer(
          company: company, warehouse: warehouse, employee: employee,
          stock_id: stock.id, quantity: 1, destination_warehouse_id: warehouse.id
        )
      }.to raise_error(Inventory::Error, "Choose a different destination warehouse.")
    end

    it "rejects receiving a transfer that is not in transit" do
      stock = create_stock(quantity: 5)
      transfer = company.stock_transfers.create!(
        company: company, branch: branch, warehouse: warehouse, destination_warehouse: destination,
        product: product, category: stock.category, property_mapping: stock.property_mapping,
        code: "STKTR-DRAFT", name: "Draft", quantity: 1, business_type: :transfer, workflow_status: :pending
      )
      transfer.stock_transfer_stock_appointments.create!(company: company, stock: stock, quantity: 1)

      expect {
        described_class.receive(company: company, warehouse: destination, employee: employee, transfer_id: transfer.id)
      }.to raise_error(Inventory::Error, "Transfer must be in transit before it can be received.")
    end
  end

  describe Inventory::ExportService do
    it "removes stock from the source and creates no destination row" do
      stock = create_stock(quantity: 20)

      result = described_class.export(
        company: company, warehouse: warehouse, employee: employee,
        stock_id: stock.id, quantity: 5, reference: "Donation"
      )

      expect(stock.reload.quantity).to eq(15)
      expect(result[:message]).to include("Exported 5", "on hand 20 → 15", "Donation")
      export = company.stock_exports.find(result[:export_id])
      expect(export.workflow_status).to eq("shipped")
      expect(company.stocks.exists?(warehouse_id: destination.id, product_id: product.id)).to be(false)
    end

    it "requires a reference and enough available stock" do
      stock = create_stock(quantity: 5)

      expect {
        described_class.export(company: company, warehouse: warehouse, employee: employee,
          stock_id: stock.id, quantity: 1, reference: "")
      }.to raise_error(Inventory::Error, "Enter a reference for this export.")

      expect {
        described_class.export(company: company, warehouse: warehouse, employee: employee,
          stock_id: stock.id, quantity: 6, reference: "Donation")
      }.to raise_error(Inventory::Error, "Only 5 available in Branch 1 Warehouse.")
      expect(stock.reload.quantity).to eq(5)
    end
  end

  describe Inventory::AdjustmentService do
    it "sets the new on hand, keeps reserved untouched and stores the reason" do
      stock = create_stock(quantity: 20, pending: 12)

      result = described_class.adjust(
        company: company, warehouse: warehouse, employee: employee,
        stock_id: stock.id, new_on_hand: 15, reason: "Damage", note: "Torn bag"
      )

      stock.reload
      expect(stock.quantity).to eq(15)
      expect(stock.pending).to eq(12)
      expect(result[:message]).to include("on hand 20 → 15", "Damage")
      adjustment = company.stock_adjustments.find(result[:adjustment_id])
      expect(adjustment.reason).to eq("Damage")
      expect(adjustment.description).to eq("Torn bag")
      expect(adjustment.direction).to eq("decrease")
    end

    it "blocks adjusting below reserved with the exact message" do
      stock = create_stock(quantity: 20, pending: 12)

      expect {
        described_class.adjust(company: company, warehouse: warehouse, employee: employee,
          stock_id: stock.id, new_on_hand: 10, reason: "Damage")
      }.to raise_error(Inventory::Error, "On hand cannot be less than the 12 reserved.")
      expect(stock.reload.quantity).to eq(20)
    end

    it "rejects a same value, an unknown reason and Other without a note" do
      stock = create_stock(quantity: 20, pending: 0)

      expect {
        described_class.adjust(company: company, warehouse: warehouse, employee: employee,
          stock_id: stock.id, new_on_hand: 20, reason: "Damage")
      }.to raise_error(Inventory::Error, "New on hand must differ from the current on hand.")

      expect {
        described_class.adjust(company: company, warehouse: warehouse, employee: employee,
          stock_id: stock.id, new_on_hand: 19, reason: "Something")
      }.to raise_error(Inventory::Error, "Choose a valid reason.")

      expect {
        described_class.adjust(company: company, warehouse: warehouse, employee: employee,
          stock_id: stock.id, new_on_hand: 19, reason: "Other")
      }.to raise_error(Inventory::Error, "Add a note for Other.")
    end
  end

  describe Inventory::ReorderService do
    let(:supplier) { create(:supplier, company: company, name: "Fresh Foods") }

    it "creates a purchase draft with one line and reuses it on the second press" do
      product.update!(default_supplier: supplier)
      stock = create_stock(quantity: 2)

      result = described_class.create(company: company, warehouse: warehouse, employee: employee, stock_id: stock.id)

      purchase = Purchase.find(result[:purchase][:id])
      expect(purchase.warehouse).to eq(warehouse)
      expect(purchase.supplier).to eq(supplier)
      expect(purchase.business_type).to eq("stock_reorder")
      expect(purchase.purchase_purchase_item_appointments.first.quantity).to eq(8)
      expect(purchase.purchase_purchase_item_appointments.first.purchase_item.product_id).to eq(product.id)
      expect(result[:message]).to include("drafted", "8 × Product 1")

      second = described_class.create(company: company, warehouse: warehouse, employee: employee, stock_id: stock.id)

      expect(second[:existing]).to be(true)
      expect(company.purchases.count).to eq(1)
    end

    it "requires a supplier when the product has none" do
      stock = create_stock(quantity: 2)

      expect {
        described_class.create(company: company, warehouse: warehouse, employee: employee, stock_id: stock.id)
      }.to raise_error(Inventory::Error, "Choose a supplier for this purchase.")
    end

    it "creates the purchase for an Out row with the full reorder point as the shortfall" do
      product.update!(default_supplier: supplier)
      stock = create_stock(quantity: 0)

      result = described_class.create(company: company, warehouse: warehouse, employee: employee, stock_id: stock.id)

      expect(result[:message]).to include("10 × Product 1")
      expect(company.purchases.last.purchase_purchase_item_appointments.first.quantity).to eq(10)
    end

    it "rejects a row that is not below its reorder point" do
      product.update!(default_supplier: supplier)
      stock = create_stock(quantity: 50)

      expect {
        described_class.create(company: company, warehouse: warehouse, employee: employee, stock_id: stock.id)
      }.to raise_error(Inventory::Error, "This item is not below its reorder point.")
    end
  end

  describe Inventory::CountService do
    it "starts a count, saves progress and submits adjustments" do
      first = create_stock(quantity: 10)
      second = create_stock(quantity: 5, record_product: create(:product, company: company, name: "Product 2", business_type: :physical))

      started = described_class.start(company: company, warehouse: warehouse, employee: employee)
      count = started[:count]
      expect(count[:status]).to eq("in_progress")
      expect(count[:rows_total]).to eq(2)

      lines = count[:lines]
      first_line = lines.find { |line| line[:stock_id] == first.id }
      second_line = lines.find { |line| line[:stock_id] == second.id }

      saved = described_class.save_progress(
        company: company, warehouse: warehouse, count_id: count[:id],
        lines: [ { id: first_line[:id], counted_quantity: 8 }, { id: second_line[:id], counted_quantity: 5 } ]
      )
      expect(saved[:count][:rows_counted]).to eq(2)
      expect(saved[:count][:net_variance]).to eq(-2)

      submitted = described_class.submit(
        company: company, warehouse: warehouse, employee: employee, count_id: count[:id]
      )

      expect(submitted[:errors]).to eq([])
      expect(first.reload.quantity).to eq(8)
      expect(second.reload.quantity).to eq(5)
      expect(company.stock_adjustments.where(reason: "Count").count).to eq(1)
      expect(StockCount.find(count[:id]).status).to eq("completed")
      expect(StockCount.find(count[:id]).metadata["completed_by_name"]).to eq(employee.name)
    end

    it "blocks a second open count for the same warehouse" do
      create_stock(quantity: 10)
      described_class.start(company: company, warehouse: warehouse, employee: employee)

      expect {
        described_class.start(company: company, warehouse: warehouse, employee: employee)
      }.to raise_error(Inventory::Error, "A count is already in progress for this warehouse.")
    end

    it "allows a zero-variance submit and still records the count" do
      create_stock(quantity: 10)
      started = described_class.start(company: company, warehouse: warehouse, employee: employee)

      result = described_class.submit(
        company: company, warehouse: warehouse, employee: employee, count_id: started[:count][:id]
      )

      expect(result[:errors]).to eq([])
      expect(StockCount.find(started[:count][:id]).status).to eq("completed")
      expect(company.stock_adjustments.where(reason: "Count").count).to eq(0)
    end

    it "skips a reserved violation with a named error and posts the rest" do
      first = create_stock(quantity: 10, pending: 6)
      second = create_stock(quantity: 10, record_product: create(:product, company: company, name: "Product 2", business_type: :physical))
      started = described_class.start(company: company, warehouse: warehouse, employee: employee)
      lines = started[:count][:lines]

      result = described_class.submit(
        company: company, warehouse: warehouse, employee: employee, count_id: started[:count][:id],
        lines: [
          { id: lines.find { |line| line[:stock_id] == first.id }[:id], counted_quantity: 4 },
          { id: lines.find { |line| line[:stock_id] == second.id }[:id], counted_quantity: 7 }
        ]
      )

      expect(result[:errors].first).to include("on hand cannot be less than the 6 reserved")
      expect(first.reload.quantity).to eq(10)
      expect(second.reload.quantity).to eq(7)
      expect(StockCount.find(started[:count][:id]).metadata["failed_lines"].length).to eq(1)
    end

    it "adjusts against the current on hand, not only the snapshot" do
      stock = create_stock(quantity: 10)
      started = described_class.start(company: company, warehouse: warehouse, employee: employee)
      stock.update_columns(quantity: 7)

      result = described_class.submit(
        company: company, warehouse: warehouse, employee: employee, count_id: started[:count][:id],
        lines: [ { id: started[:count][:lines].first[:id], counted_quantity: 10 } ]
      )

      expect(result[:errors]).to eq([])
      expect(stock.reload.quantity).to eq(10)
    end

    it "rejects starting with no stock rows" do
      expect {
        described_class.start(company: company, warehouse: warehouse, employee: employee)
      }.to raise_error(Inventory::Error, "There are no stock rows to count in this warehouse.")
    end
  end
end
