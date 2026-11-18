# spec/models/stock_lot_spec.rb
require "rails_helper"

RSpec.describe StockLot, type: :model do
  describe "table" do
    it "uses stock_lots" do
      expect(described_class.table_name).to eq("stock_lots")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:product) }
    it { should belong_to(:warehouse) }
    it { should belong_to(:supplier).optional }
    it { should have_many(:stock_serials).dependent(:nullify) }
    it { should have_many(:stock_transactions).dependent(:restrict_with_error) }
  end

  describe "validations" do
    it { should validate_presence_of(:lot_code) }
    it { should validate_length_of(:lot_code).is_at_most(64) }
    it "declares lot_code uniqueness scoped to company_id, product_id, warehouse_id" do
      validator = described_class.validators_on(:lot_code).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[company_id product_id warehouse_id])
    end
  end

  describe "enums" do
    it { should define_enum_for(:status).with_prefix(true).with_values(open: 0, quarantine: 1, consumed: 2, expired: 3, scrapped: 4) }
  end

describe "#expired?" do
  it "reports expiry from the lot date" do
    expect(described_class.new(expires_on: Date.current - 1)).to be_expired
  end
end
end
