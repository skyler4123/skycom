# spec/models/cost_center_spec.rb
require "rails_helper"

RSpec.describe CostCenter, type: :model do
  describe "table" do
    it "uses cost_centers" do
      expect(described_class.table_name).to eq("cost_centers")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:parent).class_name("CostCenter").optional }
    it { should belong_to(:branch).optional }
    it { should belong_to(:manager_employee).class_name("Employee").optional }
    it { should have_many(:children).class_name("CostCenter").dependent(:restrict_with_error) }
    it { should have_many(:employees).dependent(:nullify) }
    it { should have_many(:journal_lines).dependent(:restrict_with_error) }
    it { should have_many(:budgets).dependent(:restrict_with_error) }
  end

  describe "validations" do
    it { should validate_presence_of(:code) }
    it { should validate_length_of(:code).is_at_most(32) }
    it "declares code uniqueness scoped to company_id" do
      validator = described_class.validators_on(:code).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[company_id])
    end
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
  end
end
