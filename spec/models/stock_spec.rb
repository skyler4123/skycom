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

  describe "availability wrappers" do
    let(:company) { create(:company) }
    let(:product) { create(:product, company: company) }
    let(:warehouse) { create(:warehouse, company: company) }
    let!(:stock) do
      Stock.create!(
        company: company, product: product, warehouse: warehouse,
        quantity: 10, pending: 0, name: "Wrapper Stock", code: "STK-WRAP"
      )
    end

    describe "#available_count" do
      it "reads the synced counter" do
        expect(stock.available_count).to eq(10)
      end

      it "heals from DB when the counter key is missing" do
        Kredis.redis.del("stock:#{stock.id}:available")

        expect(stock.available_count).to eq(10)
        expect(stock.available_counter.exists?).to be_truthy
      end
    end

    describe "#reserve_stock!" do
      it "decrements availability and promises pending" do
        expect(stock.reserve_stock!(3)).to be true
        expect(stock.reload.pending).to eq(3)
        expect(stock.available_count).to eq(7)
      end

      it "returns false without side effects when insufficient" do
        expect(stock.reserve_stock!(11)).to be false
        expect(stock.reload.pending).to eq(0)
        expect(stock.available_count).to eq(10)
      end
    end

    describe "#release_reserved!" do
      it "restores availability and consumes pending" do
        stock.reserve_stock!(4)

        stock.release_reserved!(4)

        expect(stock.reload.pending).to eq(0)
        expect(stock.available_count).to eq(10)
      end
    end
  end

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
        pending: 0
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
        pending: 0
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
        pending: 0
      )
      stock.validate
      expect(stock.category_id).to eq(product.category_id)
    end
  end
end
