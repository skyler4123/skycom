# spec/models/tax_code_spec.rb
require "rails_helper"

RSpec.describe TaxCode, type: :model do
  describe "table" do
    it "uses tax_codes" do
      expect(described_class.table_name).to eq("tax_codes")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:ledger_account).optional }
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
    it { should validate_numericality_of(:rate_bp).only_integer.is_greater_than_or_equal_to(0).is_less_than_or_equal_to(10000) }
  end

  describe "enums" do
    it { should define_enum_for(:kind).with_prefix(true).with_values(vat: 0, gst: 1, sales: 2, withholding: 3) }
  end

describe "rate arithmetic" do
  it "converts basis points to a rate" do
    expect(described_class.new(rate_bp: 850).rate).to eq(0.085)
  end

  it "calculates tax on integer cents" do
    expect(described_class.new(rate_bp: 1_000).tax_for_cents(12_345)).to eq(1_235)
  end
end
end
