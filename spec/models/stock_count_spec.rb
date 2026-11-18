# spec/models/stock_count_spec.rb
require "rails_helper"

RSpec.describe StockCount, type: :model do
  describe "table" do
    it "uses stock_counts" do
      expect(described_class.table_name).to eq("stock_counts")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:warehouse) }
    it { should belong_to(:created_by_employee).class_name("Employee").optional }
    it { should have_many(:stock_count_lines).dependent(:destroy) }
  end

  describe "enums" do
    it { should define_enum_for(:count_type).with_prefix(true).with_values(full: 0, cycle: 1, spot: 2, blind: 3) }
  end
end
