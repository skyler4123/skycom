require 'rails_helper'

RSpec.describe StockMovementService::BaseService, type: :model do
  let(:company) { create(:company) }
  let(:product) { create(:product, company: company) }
  let(:warehouse) { create(:warehouse, company: company) }
  let!(:stock) do
    Stock.create!(
      company: company, warehouse: warehouse, product: product,
      quantity: 10, pending: 4, name: "Service Stock", code: "STK-SVC"
    )
  end
  let(:document) { create(:stock_export, company: company, warehouse: warehouse, product: product, category: stock.category, property_mapping: stock.property_mapping) }
  let(:employee) { create(:employee, company: company) }

  def call(**overrides)
    described_class.call(
      stock: stock, quantity: 3, direction: :remove, transaction_type: :export,
      document: document, employee: employee, **overrides
    )
  end

  describe "success" do
    it "creates the ledger row and mutates quantity via the callback" do
      expect { call }.to change(StockTransaction, :count).by(1)

      expect(stock.reload.quantity).to eq(7)
    end

    it "points the ledger row at the document and employee" do
      result = call

      txn = result[:stock_transaction]
      expect(txn.appoint_for).to eq(document)
      expect(txn.appoint_by).to eq(employee)
      expect(txn.branch_id).to eq(stock.branch_id)
    end

    it "adds quantity for add direction" do
      call(direction: :add, transaction_type: :import)

      expect(stock.reload.quantity).to eq(13)
    end
  end

  describe "hold-aware floor" do
    it "rejects a free-standing removal that would consume pending units" do
      # quantity 10, pending 4 → available 6; removing 7 must fail
      expect {
        call(quantity: 7)
      }.to raise_error(StockMovementService::Error, /Insufficient stock: available 6/)

      expect(stock.reload.quantity).to eq(10)
      expect(stock.reload.pending).to eq(4)
    end

    it "allows a free-standing removal up to available" do
      expect { call(quantity: 6) }.not_to raise_error
      expect(stock.reload.quantity).to eq(4)
      expect(stock.reload.pending).to eq(4)
    end

    it "consumes the hold when consume_hold is set" do
      call(quantity: 4, consume_hold: true)

      expect(stock.reload.quantity).to eq(6)
      expect(stock.reload.pending).to eq(0)
      expect(stock.available_count).to eq(6)
    end

    it "rejects consuming a hold larger than pending" do
      expect {
        call(quantity: 5, consume_hold: true)
      }.to raise_error(StockMovementService::Error, /Insufficient stock to consume hold/)

      expect(stock.reload.pending).to eq(4)
    end
  end

  describe "validation" do
    it "rejects non-positive quantity" do
      expect { call(quantity: 0) }.to raise_error(StockMovementService::Error, /greater than 0/)
    end

    it "rejects invalid direction" do
      expect { call(direction: :sideways) }.to raise_error(StockMovementService::Error, /Invalid direction/)
    end

    it "rejects import with remove direction" do
      expect { call(direction: :remove, transaction_type: :import) }
        .to raise_error(StockMovementService::Error, /Import transactions must be add/)
    end

    it "rejects export with add direction" do
      expect { call(direction: :add, transaction_type: :export) }
        .to raise_error(StockMovementService::Error, /Export transactions must be remove/)
    end

    it "rejects consume_hold with add direction" do
      expect { call(direction: :add, transaction_type: :import, consume_hold: true) }
        .to raise_error(StockMovementService::Error, /consume_hold is only valid for remove/)
    end
  end

  describe "rollback semantics" do
    it "creates nothing when the floor check fails" do
      expect {
        call(quantity: 99)
      }.to raise_error(StockMovementService::Error)

      expect(StockTransaction.count).to eq(0)
    end
  end
end
