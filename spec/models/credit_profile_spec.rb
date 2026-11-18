# spec/models/credit_profile_spec.rb
require "rails_helper"

RSpec.describe CreditProfile, type: :model do
  describe "table" do
    it "uses credit_profiles" do
      expect(described_class.table_name).to eq("credit_profiles")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:customer) }
    it { should belong_to(:reviewed_by_employee).class_name("Employee").optional }
  end

  describe "validations" do
    it { should validate_numericality_of(:limit_cents).only_integer.is_greater_than_or_equal_to(0) }
    it "declares customer_id uniqueness scoped to company_id" do
      validator = described_class.validators_on(:customer_id).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[company_id])
    end
  end

describe "#exceeded_by?" do
  it "treats a zero limit as unlimited" do
    expect(described_class.new(limit_cents: 0).exceeded_by?(5_000_000)).to be(false)
  end

  it "flags a balance above the limit" do
    expect(described_class.new(limit_cents: 10_000).exceeded_by?(10_001)).to be(true)
  end
end
end
