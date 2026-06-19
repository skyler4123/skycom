# spec/models/stock_spec.rb
require 'rails_helper'

RSpec.describe Stock, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:warehouse) }
    it { should belong_to(:category) }
    it { should have_many(:tag_appointments).dependent(:destroy) }
    it { should have_many(:tags).through(:tag_appointments) }
  end
  it_behaves_like "property_mapping concern", Stock

  describe "category must match product's category" do
    let(:company) { create(:company) }
    let(:product) { create(:product, company: company) }
    let(:category) { product.category }
    let(:warehouse) { create(:warehouse, company: company) }

    it "does not error when category matches product's category" do
      stock = Stock.new(
        company: company,
        product: product,
        warehouse: warehouse,
        category: category,
        quantity: 10,
        reorder: 0
      )
      stock.valid?
      expect(stock.errors[:category]).to be_blank
    end

    it "errors when category differs from product's category" do
      other_category = create(:category, name: "Other #{SecureRandom.uuid}", company: company)
      stock = Stock.new(
        company: company,
        product: product,
        warehouse: warehouse,
        category: other_category,
        quantity: 10,
        reorder: 0
      )
      stock.valid?
      expect(stock.errors[:category]).to include("must match product's category")
    end

    it "auto-inherits category from product on create" do
      stock = Stock.new(
        company: company,
        product: product,
        warehouse: warehouse,
        quantity: 10,
        reorder: 0
      )
      stock.validate
      expect(stock.category_id).to eq(product.category_id)
    end
  end
end
