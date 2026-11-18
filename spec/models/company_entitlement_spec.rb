# spec/models/company_entitlement_spec.rb
require "rails_helper"

RSpec.describe CompanyEntitlement, type: :model do
  describe "table" do
    it "uses company_entitlements" do
      expect(described_class.table_name).to eq("company_entitlements")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
  end

  describe "validations" do
    it { should validate_presence_of(:feature_key) }
    it { should validate_length_of(:feature_key).is_at_most(64) }
    it "declares feature_key uniqueness scoped to company_id" do
      validator = described_class.validators_on(:feature_key).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[company_id])
    end
  end

describe "#active?" do
  it "is inactive once expired" do
    expect(described_class.new(is_enabled: true, expires_at: 1.day.ago)).not_to be_active
    expect(described_class.new(is_enabled: true, expires_at: 1.day.from_now)).to be_active
  end

  it "is inactive when switched off even without an expiry" do
    expect(described_class.new(is_enabled: false)).not_to be_active
  end
end
end
