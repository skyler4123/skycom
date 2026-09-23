require 'rails_helper'

RSpec.describe StockItemAppointment, type: :model do
  let(:company) { create(:company) }
  let(:product) { create(:product, company: company) }
  let(:warehouse) { create(:warehouse, company: company) }
  let!(:stock) do
    Stock.create!(company: company, warehouse: warehouse, product: product, quantity: 5, name: "Item Stock", code: "STK-ITM")
  end
  let(:document) { create(:stock_import, company: company, warehouse: warehouse, product: product) }

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:stock) }
    it { should belong_to(:appoint_to) }
  end

  describe "validations" do
    subject { described_class.new(company: company, stock: stock, appoint_to: document, quantity: 2) }

    it { should validate_numericality_of(:quantity).only_integer.is_greater_than(0) }

    it "is valid with matching companies" do
      expect(subject).to be_valid
    end

    it "rejects a stock from another company" do
      other_company = create(:company)
      foreign_stock = create(:product, company: other_company)
      other_warehouse = create(:warehouse, company: other_company)
      stock_other = Stock.create!(company: other_company, warehouse: other_warehouse, product: foreign_stock, quantity: 1, name: "X", code: "STK-X1")

      subject.stock = stock_other

      expect(subject).not_to be_valid
      expect(subject.errors[:stock]).to be_present
    end

    it "derives company from appoint_to when blank" do
      appointment = described_class.new(stock: stock, appoint_to: document, quantity: 1)
      expect(appointment).to be_valid

      expect(appointment.company_id).to eq(company.id)
    end
  end
end
