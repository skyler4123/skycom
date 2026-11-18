# spec/models/stock_count_line_spec.rb
require "rails_helper"

RSpec.describe StockCountLine, type: :model do
  describe "table" do
    it "uses stock_count_lines" do
      expect(described_class.table_name).to eq("stock_count_lines")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:stock_count) }
    it { should belong_to(:stock) }
    it { should belong_to(:storage_location).optional }
  end

  describe "validations" do
    it { should validate_numericality_of(:expected_quantity).only_integer }
    it "declares stock_id uniqueness scoped to stock_count_id" do
      validator = described_class.validators_on(:stock_id).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[stock_count_id])
    end
  end
end
