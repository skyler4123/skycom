# spec/services/seed/stock_line_service_spec.rb
require 'rails_helper'

RSpec.describe Seed::StockLineService do
  let(:company) { create(:company) }
  let(:warehouse) { create(:warehouse, company: company) }
  let(:product_a) { create(:product, company: company, name: "LineA #{SecureRandom.hex(4)}") }
  let(:product_b) { create(:product, company: company, name: "LineB #{SecureRandom.hex(4)}") }
  let!(:stock_a) do
    Stock.create!(company: company, warehouse: warehouse, product: product_a,
      quantity: 40, name: "SeedLine-A", code: "STK-SLNA-#{SecureRandom.hex(3).upcase}")
  end
  let!(:stock_b) do
    Stock.create!(company: company, warehouse: warehouse, product: product_b,
      quantity: 30, name: "SeedLine-B", code: "STK-SLNB-#{SecureRandom.hex(3).upcase}")
  end

  describe ".attach!" do
    it "creates one line per product without touching stock quantities (no ledger)" do
      import = Seed::StockImportService.create(company: company, warehouse: warehouse, product: product_a)

      expect {
        described_class.attach!(document: import, company: company, warehouse: warehouse,
          lines: [ [ product_a, 10 ], [ product_b, 6 ] ])
      }.not_to change { Stock.find(stock_a.id).quantity }

      rows = import.reload.stock_import_stock_appointments.order(:quantity)
      expect(rows.map(&:quantity)).to eq([ 6, 10 ])
      expect(rows.map { |r| r.stock.product_id }).to contain_exactly(product_a.id, product_b.id)
    end

    it "attaches transfer lines against the source warehouse stock" do
      dest = create(:warehouse, company: company)
      transfer = Seed::StockTransferService.create(company: company, warehouse: warehouse,
        destination_warehouse: dest, product: product_a)

      described_class.attach!(document: transfer, company: company, warehouse: warehouse,
        lines: [ [ product_a, 4 ] ])

      line = transfer.reload.stock_transfer_stock_appointments.first
      expect(line.stock_id).to eq(stock_a.id)
      expect(line.quantity).to eq(4)
    end
  end

  describe ".split_quantity" do
    it "splits evenly with remainder spread over leading parts" do
      expect(described_class.split_quantity(10, 3)).to eq([ 4, 3, 3 ])
    end

    it "returns singletons and preserves the total" do
      expect(described_class.split_quantity(1, 1)).to eq([ 1 ])
      [ 7, 60, 101 ].each do |total|
        parts = described_class.split_quantity(total, 3)
        expect(parts.size).to eq(3)
        expect(parts.sum).to eq(total)
        expect(parts).to all(be >= 1)
      end
    end
  end

  describe "missing stock" do
    it "raises a naming error when a product has no stock row in the warehouse" do
      other_product = create(:product, company: company, name: "Ghost #{SecureRandom.hex(4)}")
      export = Seed::StockExportService.create(company: company, warehouse: warehouse, product: product_a)

      expect {
        described_class.attach!(document: export, company: company, warehouse: warehouse,
          lines: [ [ other_product, 2 ] ])
      }.to raise_error(Seed::StockLineService::Error, /no stock row/)
    end
  end
end
