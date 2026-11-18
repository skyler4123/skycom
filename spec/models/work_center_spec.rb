# spec/models/work_center_spec.rb
require "rails_helper"

RSpec.describe WorkCenter, type: :model do
  describe "table" do
    it "uses work_centers" do
      expect(described_class.table_name).to eq("work_centers")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should have_many(:production_operations).dependent(:restrict_with_error) }
    it { should have_many(:production_order_operations).dependent(:restrict_with_error) }
    it { should have_many(:machine_readings).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
    it "declares name uniqueness scoped to company_id" do
      validator = described_class.validators_on(:name).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[company_id])
    end
    it { should validate_numericality_of(:capacity_per_hour).is_greater_than(0) }
    it { should validate_numericality_of(:cost_per_hour_cents).only_integer.is_greater_than_or_equal_to(0) }
  end
end
