# spec/models/landed_cost_allocation_spec.rb
require "rails_helper"

RSpec.describe LandedCostAllocation, type: :model do
  describe "table" do
    it "uses landed_cost_allocations" do
      expect(described_class.table_name).to eq("landed_cost_allocations")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:landed_cost_charge) }
    it { should belong_to(:stock) }
    it { should belong_to(:product) }
  end

  describe "validations" do
    it { should validate_numericality_of(:allocated_cents).only_integer.is_greater_than_or_equal_to(0) }
    it "declares stock_id uniqueness scoped to landed_cost_charge_id" do
      validator = described_class.validators_on(:stock_id).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[landed_cost_charge_id])
    end
  end
end
