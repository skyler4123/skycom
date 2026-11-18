# spec/models/reorder_rule_spec.rb
require "rails_helper"

RSpec.describe ReorderRule, type: :model do
  describe "table" do
    it "uses reorder_rules" do
      expect(described_class.table_name).to eq("reorder_rules")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:product) }
    it { should belong_to(:warehouse) }
  end

  describe "validations" do
    it { should validate_numericality_of(:min_quantity).only_integer.is_greater_than_or_equal_to(0) }
    it "declares product_id uniqueness scoped to warehouse_id" do
      validator = described_class.validators_on(:product_id).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[warehouse_id])
    end
  end

  describe "enums" do
    it { should define_enum_for(:auto_action).with_prefix(true).with_values(purchase_requisition: 0, stock_transfer: 1, notify_only: 2) }
  end

describe "replenishment" do
  it "triggers at or below minimum plus safety stock" do
    rule = described_class.new(min_quantity: 10, safety_stock: 5, max_quantity: 50)

    expect(rule.below_trigger?(15)).to be(true)
    expect(rule.below_trigger?(16)).to be(false)
  end

  it "suggests enough to reach the maximum" do
    rule = described_class.new(min_quantity: 10, safety_stock: 5, max_quantity: 50)

    expect(rule.suggested_quantity(20)).to eq(30)
    expect(rule.suggested_quantity(60)).to eq(0)
  end
end
end
