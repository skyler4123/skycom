# spec/models/data_retention_policy_spec.rb
require "rails_helper"

RSpec.describe DataRetentionPolicy, type: :model do
  describe "table" do
    it "uses data_retention_policies" do
      expect(described_class.table_name).to eq("data_retention_policies")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
  end

  describe "validations" do
    it { should validate_presence_of(:resource_name) }
    it { should validate_length_of(:resource_name).is_at_most(64) }
    it "declares resource_name uniqueness scoped to company_id" do
      validator = described_class.validators_on(:resource_name).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[company_id])
    end
    it { should validate_numericality_of(:retention_days).only_integer.is_greater_than(0) }
  end

  describe "enums" do
    it { should define_enum_for(:action).with_prefix(true).with_values(anonymize: 0, destroy: 1, archive: 2) }
  end

describe "#cutoff_date" do
  it "computes the cutoff from the retention window" do
    policy = described_class.new(retention_days: 30)

    expect(policy.cutoff_date).to eq(Date.current - 30.days)
  end
end
end
