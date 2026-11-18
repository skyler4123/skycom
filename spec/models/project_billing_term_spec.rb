# spec/models/project_billing_term_spec.rb
require "rails_helper"

RSpec.describe ProjectBillingTerm, type: :model do
  describe "table" do
    it "uses project_billing_terms" do
      expect(described_class.table_name).to eq("project_billing_terms")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:project) }
  end

  describe "validations" do
    it "declares project_id uniqueness scoped to company_id" do
      validator = described_class.validators_on(:project_id).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[company_id])
    end
    it { should validate_numericality_of(:rate_cents).only_integer.is_greater_than_or_equal_to(0) }
  end

  describe "enums" do
    it { should define_enum_for(:billing_model).with_prefix(true).with_values(fixed_price: 0, milestone: 1, time_and_materials: 2, retainer: 3) }
  end

describe "#cap_reached?" do
  it "only applies when a cap is set" do
    expect(described_class.new(cap_cents: 1_000).cap_reached?(1_000)).to be(true)
    expect(described_class.new(cap_cents: nil).cap_reached?(10_000_000)).to be(false)
  end
end
end
