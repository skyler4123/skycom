# spec/models/budget_spec.rb
require "rails_helper"

RSpec.describe Budget, type: :model do
  describe "table" do
    it "uses budgets" do
      expect(described_class.table_name).to eq("budgets")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:cost_center).optional }
    it { should belong_to(:fiscal_period).optional }
    it { should belong_to(:workflow_step).optional }
    it { should have_many(:budget_lines).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
    it "declares name uniqueness scoped to company_id" do
      validator = described_class.validators_on(:name).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[company_id])
    end
    it { should validate_numericality_of(:amount_cents).only_integer.is_greater_than_or_equal_to(0) }
  end

  describe "enums" do
    it { should define_enum_for(:budget_scope).with_prefix(true).with_values(company: 0, branch: 1, cost_center: 2) }
  end
end
