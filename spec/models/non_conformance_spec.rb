# spec/models/non_conformance_spec.rb
require "rails_helper"

RSpec.describe NonConformance, type: :model do
  describe "table" do
    it "uses non_conformances" do
      expect(described_class.table_name).to eq("non_conformances")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:quality_inspection).optional }
    it { should belong_to(:production_order).optional }
    it { should belong_to(:stock_import).optional }
    it { should belong_to(:product).optional }
  end

  describe "validations" do
    it { should validate_presence_of(:description) }
    it { should validate_length_of(:description).is_at_most(5000) }
  end

  describe "enums" do
    it { should define_enum_for(:severity).with_prefix(true).with_values(minor: 0, major: 1, critical: 2) }
    it { should define_enum_for(:disposition).with_prefix(true).with_values(use_as_is: 0, rework: 1, scrap: 2, return_to_supplier: 3) }
  end
end
