# spec/models/production_operation_spec.rb
require "rails_helper"

RSpec.describe ProductionOperation, type: :model do
  describe "table" do
    it "uses production_operations" do
      expect(described_class.table_name).to eq("production_operations")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:production_routing) }
    it { should belong_to(:work_center).optional }
    it { should have_many(:production_order_operations).dependent(:restrict_with_error) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
    it { should validate_numericality_of(:position).only_integer.is_greater_than(0) }
    it "declares position uniqueness scoped to production_routing_id" do
      validator = described_class.validators_on(:position).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[production_routing_id])
    end
    it { should validate_numericality_of(:setup_minutes).only_integer.is_greater_than_or_equal_to(0) }
  end

describe "#planned_minutes_for" do
  it "adds setup time to per-unit run time" do
    operation = described_class.new(setup_minutes: 15, run_minutes_per_unit: 2)

    expect(operation.planned_minutes_for(10)).to eq(35)
  end
end
end
