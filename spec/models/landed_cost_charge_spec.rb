# spec/models/landed_cost_charge_spec.rb
require "rails_helper"

RSpec.describe LandedCostCharge, type: :model do
  describe "table" do
    it "uses landed_cost_charges" do
      expect(described_class.table_name).to eq("landed_cost_charges")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:stock_import) }
    it { should belong_to(:supplier).optional }
    it { should have_many(:landed_cost_allocations).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_numericality_of(:amount_cents).only_integer.is_greater_than_or_equal_to(0) }
  end

  describe "enums" do
    it { should define_enum_for(:charge_type).with_prefix(true).with_values(freight: 0, duty: 1, insurance: 2, handling: 3, other: 4) }
    it { should define_enum_for(:allocation_method).with_prefix(true).with_values(by_quantity: 0, by_value: 1, by_weight: 2, by_volume: 3, equal: 4) }
  end
end
