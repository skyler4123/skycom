# spec/models/price_list_item_spec.rb
require "rails_helper"

RSpec.describe PriceListItem, type: :model do
  describe "table" do
    it "uses price_list_items" do
      expect(described_class.table_name).to eq("price_list_items")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:price_list) }
    it { should belong_to(:product).optional }
    it { should belong_to(:service).optional }
  end

  describe "validations" do
    it { should validate_numericality_of(:min_quantity).only_integer.is_greater_than(0) }
    it { should validate_numericality_of(:price_cents).only_integer.is_greater_than_or_equal_to(0) }
  end

describe "resource" do
  it "rejects a line with both a product and a service" do
    item = described_class.new(product_id: SecureRandom.uuid, service_id: SecureRandom.uuid)
    item.valid?

    expect(item.errors[:base]).to include("must reference exactly one product or service")
  end
end
end
