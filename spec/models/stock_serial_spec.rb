# spec/models/stock_serial_spec.rb
require "rails_helper"

RSpec.describe StockSerial, type: :model do
  describe "table" do
    it "uses stock_serials" do
      expect(described_class.table_name).to eq("stock_serials")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:stock) }
    it { should belong_to(:stock_lot).optional }
    it { should belong_to(:storage_location).optional }
    it { should belong_to(:sold_order).class_name("Order").optional }
  end

  describe "validations" do
    it { should validate_presence_of(:serial_number) }
    it { should validate_length_of(:serial_number).is_at_most(128) }
    it "declares serial_number uniqueness scoped to company_id" do
      validator = described_class.validators_on(:serial_number).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[company_id])
    end
  end

  describe "enums" do
    it { should define_enum_for(:status).with_prefix(true).with_values(in_stock: 0, reserved: 1, sold: 2, returned: 3, scrapped: 4) }
  end
end
