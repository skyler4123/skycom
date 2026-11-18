# spec/models/maintenance_check_spec.rb
require "rails_helper"

RSpec.describe MaintenanceCheck, type: :model do
  describe "table" do
    it "uses maintenance_checks" do
      expect(described_class.table_name).to eq("maintenance_checks")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:maintenance_plan) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
    it { should validate_numericality_of(:position).only_integer.is_greater_than(0) }
    it "declares position uniqueness scoped to maintenance_plan_id" do
      validator = described_class.validators_on(:position).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[maintenance_plan_id])
    end
  end
end
