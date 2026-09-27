require "rails_helper"

RSpec.describe StockImportStockAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:stock_import) }
    it { should belong_to(:stock) }
  end

  describe "validations" do
    it { should validate_numericality_of(:quantity).only_integer.is_greater_than(0) }
  end

  describe "derives company from the document" do
    it "sets company_id when not given" do
      company = create(:company)
      warehouse = create(:warehouse, company: company)
      product = create(:product, company: company)
      stock = Stock.create!(company: company, warehouse: warehouse, product: product, quantity: 5, name: "S", code: "STK-S1")
      document = create(:stock_import, company: company, warehouse: warehouse, product: product)

      line = described_class.create!(stock_import: document, stock: stock, quantity: 2)

      expect(line.company_id).to eq(company.id)
    end
  end
end
