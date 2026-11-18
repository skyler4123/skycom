# spec/models/production_order_material_spec.rb
require "rails_helper"

RSpec.describe ProductionOrderMaterial, type: :model do
  describe "table" do
    it "uses production_order_materials" do
      expect(described_class.table_name).to eq("production_order_materials")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:production_order) }
    it { should belong_to(:product) }
    it { should belong_to(:stock_lot).optional }
  end

  describe "validations" do
    it { should validate_numericality_of(:required_quantity).is_greater_than_or_equal_to(0) }
    it "declares product_id uniqueness scoped to production_order_id" do
      validator = described_class.validators_on(:product_id).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[production_order_id])
    end
  end

describe "#variance_quantity" do
  it "reports consumption against the snapshot" do
    material = described_class.new(required_quantity: 10, consumed_quantity: 12)

    expect(material.variance_quantity).to eq(2)
  end
end
end
