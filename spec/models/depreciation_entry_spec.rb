# spec/models/depreciation_entry_spec.rb
require "rails_helper"

RSpec.describe DepreciationEntry, type: :model do
  describe "table" do
    it "uses depreciation_entries" do
      expect(described_class.table_name).to eq("depreciation_entries")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:fixed_asset) }
    it { should belong_to(:fiscal_period) }
    it { should belong_to(:journal_entry).optional }
  end

  describe "validations" do
    it { should validate_numericality_of(:amount_cents).only_integer.is_greater_than_or_equal_to(0) }
    it "declares fiscal_period_id uniqueness scoped to fixed_asset_id" do
      validator = described_class.validators_on(:fiscal_period_id).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[fixed_asset_id])
    end
  end
end
