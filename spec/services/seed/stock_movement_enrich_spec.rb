# spec/services/seed/stock_movement_enrich_spec.rb
require 'rails_helper'

RSpec.describe "Stock movement enrich seeding" do
  def build_universe(product_count: 3)
    company = create(:company)
    user = company.user
    branch = create(:branch, company: company)
    warehouse = create(:warehouse, company: company, branch: branch)
    products = product_count.times.map do |i|
      create(:product, company: company, branch: branch, name: "EnrProd#{i} #{SecureRandom.hex(4)}")
    end
    products.each_with_index do |product, i|
      Stock.create!(company: company, warehouse: warehouse, product: product,
        quantity: 60, name: product.name, code: "STK-ENR#{i}-#{SecureRandom.hex(3).upcase}")
    end
    [ company, user, branch, warehouse, products ]
  end

  def assert_lines_sum_to_header(docs, lines_assoc)
    expect(docs).not_to be_empty
    docs.each do |doc|
      lines = doc.public_send(lines_assoc)
      expect(lines).not_to be_empty
      expect(lines.sum(&:quantity)).to eq(doc.quantity)
    end
  end

  # StockAdjustment has no header quantity column — lines are the only truth.
  def assert_adjustment_lines(docs)
    expect(docs).not_to be_empty
    docs.each do |doc|
      lines = doc.stock_adjustment_stock_appointments
      expect(lines).not_to be_empty
      lines.each { |l| expect(l.quantity).to be >= 1 }
    end
  end

  describe Seed::RetailEnrichService do
    it "seeds transfers/imports/exports with lines summing to headers" do
      company, user, branch, warehouse, products = build_universe
      service = Seed::RetailEnrichService.allocate
      service.instance_variable_set(:@retail, company)
      service.instance_variable_set(:@branches, [ branch ])
      service.instance_variable_set(:@warehouses, [ warehouse ])
      service.instance_variable_set(:@products, products)

      service.send(:create_stock_transfers)
      service.send(:create_stock_imports)
      service.send(:create_stock_exports)

      assert_lines_sum_to_header(StockTransfer.where(company: company), :stock_transfer_stock_appointments)
      assert_lines_sum_to_header(StockImport.where(company: company), :stock_import_stock_appointments)
      assert_lines_sum_to_header(StockExport.where(company: company), :stock_export_stock_appointments)
    end

    it "splits every third document into two lines" do
      company, user, branch, warehouse, products = build_universe
      service = Seed::RetailEnrichService.allocate
      service.instance_variable_set(:@retail, company)
      service.instance_variable_set(:@branches, [ branch ])
      service.instance_variable_set(:@warehouses, [ warehouse ])
      service.instance_variable_set(:@products, products)

      service.send(:create_stock_transfers)

      multi = StockTransfer.where(company: company).select do |t|
        t.stock_transfer_stock_appointments.size == 2
      end
      expect(multi).not_to be_empty
    end

    it "seeds adjustments with lines and leaves quantities untouched" do
      company, user, branch, warehouse, products = build_universe
      Seed::CategoryService.find_or_create_for(company: company, resource_name: "stock_adjustments")
      before = Stock.where(company: company).sum(:quantity)
      service = Seed::RetailEnrichService.allocate
      service.instance_variable_set(:@retail, company)
      service.instance_variable_set(:@branches, [ branch ])
      service.instance_variable_set(:@warehouses, [ warehouse ])
      service.instance_variable_set(:@products, products)

      service.send(:create_stock_adjustments)

      docs = StockAdjustment.where(company: company)
      assert_adjustment_lines(docs)
      expect(Stock.where(company: company).sum(:quantity)).to eq(before)
    end
  end

  describe Seed::HospitalEnrichService do
    it "seeds adjustments with lines" do
      company, user, branch, warehouse, products = build_universe
      Seed::CategoryService.find_or_create_for(company: company, resource_name: "stock_adjustments")
      service = Seed::HospitalEnrichService.allocate
      service.instance_variable_set(:@company, company)
      service.instance_variable_set(:@branches, [ branch ])
      service.instance_variable_set(:@warehouses, [ warehouse ])
      service.instance_variable_set(:@products, products)

      service.send(:create_stock_adjustments)

      assert_adjustment_lines(StockAdjustment.where(company: company))
    end
  end
end
