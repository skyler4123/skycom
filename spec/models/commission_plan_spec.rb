# spec/models/commission_plan_spec.rb
require "rails_helper"

RSpec.describe CommissionPlan, type: :model do
  describe "table" do
    it "uses commission_plans" do
      expect(described_class.table_name).to eq("commission_plans")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:applies_to_category).class_name("Category").optional }
    it { should belong_to(:applies_to_employee_group).class_name("EmployeeGroup").optional }
    it { should have_many(:commission_tiers).dependent(:destroy) }
    it { should have_many(:commission_entries).dependent(:restrict_with_error) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
    it "declares name uniqueness scoped to company_id" do
      validator = described_class.validators_on(:name).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[company_id])
    end
  end

  describe "enums" do
    it { should define_enum_for(:basis).with_prefix(true).with_values(revenue: 0, margin: 1, collected: 2) }
  end
end
