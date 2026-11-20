# spec/models/stock_spec.rb
require 'rails_helper'

RSpec.describe Stock, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:warehouse) }
    it { should belong_to(:category) }
    it { should have_many(:stock_tag_appointments).dependent(:destroy) }
    it { should have_many(:tags).through(:stock_tag_appointments) }
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

  describe "availability buckets" do
    let(:company) { create(:company) }
    let(:warehouse) { create(:warehouse, company: company) }
    let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "stocks") }

    def stock_with(quantity:, pending:)
      product = create(:product, company: company)
      Stock.create!(company: company, warehouse: warehouse, product: product, category: category,
        property_mapping: category.default_property_mapping, name: "Row", code: "SKU-#{SecureRandom.hex(3)}",
        quantity: quantity, pending: pending)
    end

    it "reports the unclamped on-hand minus reserved figure" do
      expect(stock_with(quantity: 3, pending: 5).available_quantity).to eq(-2)
    end

    it "maps the boundary values to disjoint statuses" do
      expect(stock_with(quantity: 0, pending: 0).availability_status).to eq("out")
      expect(stock_with(quantity: 3, pending: 5).availability_status).to eq("out")
      expect(stock_with(quantity: 1, pending: 0).availability_status).to eq("low")
      expect(stock_with(quantity: 10, pending: 0).availability_status).to eq("low")
      expect(stock_with(quantity: 11, pending: 0).availability_status).to eq("in_stock")
    end

    it "keeps the SQL buckets disjoint and exhaustive" do
      out = stock_with(quantity: 0, pending: 0)
      low = stock_with(quantity: 10, pending: 0)
      healthy = stock_with(quantity: 11, pending: 0)

      expect(Stock.out_of_stock).to contain_exactly(out)
      expect(Stock.low_stock).to contain_exactly(low)
      expect(Stock.in_stock).to contain_exactly(healthy)
      expect(Stock.low_or_out).to contain_exactly(out, low)
    end

    it "exposes the status labels from one constant" do
      expect(STOCK_AVAILABILITY_LABELS).to eq("out" => "Out", "low" => "Low", "in_stock" => "In stock")
    end
  end

  describe "category taxonomy" do
    let(:company) { create(:company) }
    let(:product) { create(:product, company: company) }
    let(:warehouse) { create(:warehouse, company: company) }

    it "accepts a category independent from the product's category" do
      stocks_category = Category.create!(
        company: company, name: "Inventory #{SecureRandom.uuid}", resource_name: "stocks"
      )
      stock = Stock.new(
        company: company,
        product: product,
        warehouse: warehouse,
        category: stocks_category,
        property_mapping: stocks_category.default_property_mapping,
        quantity: 10,
        pending: 0
      )
      expect(stock).to be_valid
    end

    it "defaults to a stocks resource category on create" do
      stock = Stock.new(
        company: company,
        product: product,
        warehouse: warehouse,
        quantity: 10,
        pending: 0
      )
      stock.validate
      expect(stock.category&.resource_name).to eq("stocks")
    end

    it "derives property_mapping from its own category" do
      stocks_category = Category.create!(
        company: company, name: "Raw #{SecureRandom.uuid}", resource_name: "stocks"
      )
      stock = Stock.new(
        company: company,
        product: product,
        warehouse: warehouse,
        category: stocks_category,
        quantity: 10,
        pending: 0
      )
      stock.validate
      expect(stock.property_mapping_id).to eq(stocks_category.default_property_mapping.id)
    end
  end
end
