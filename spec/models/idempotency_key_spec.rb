# spec/models/idempotency_key_spec.rb
require "rails_helper"

RSpec.describe IdempotencyKey, type: :model do
  describe "table" do
    it "uses idempotency_keys" do
      expect(described_class.table_name).to eq("idempotency_keys")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
  end

  describe "validations" do
    it { should validate_presence_of(:key) }
    it { should validate_length_of(:key).is_at_most(255) }
    it "declares key uniqueness scoped to company_id" do
      validator = described_class.validators_on(:key).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[company_id])
    end
  end
end
