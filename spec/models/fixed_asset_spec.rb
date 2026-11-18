# spec/models/fixed_asset_spec.rb
require "rails_helper"

RSpec.describe FixedAsset, type: :model do
  describe "table" do
    it "uses fixed_assets" do
      expect(described_class.table_name).to eq("fixed_assets")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:ledger_account).optional }
    it { should belong_to(:cost_center).optional }
    it { should have_many(:depreciation_entries).dependent(:restrict_with_error) }
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
    it { should validate_presence_of(:acquired_on) }
    it { should validate_numericality_of(:useful_life_months).only_integer.is_greater_than(0) }
    it { should validate_numericality_of(:cost_cents).only_integer.is_greater_than_or_equal_to(0) }
  end

  describe "enums" do
    it { should define_enum_for(:depreciation_method).with_prefix(true).with_values(straight_line: 0, declining_balance: 1) }
  end

describe "depreciation terms" do
  it "spreads depreciable cost across the useful life" do
    asset = described_class.new(cost_cents: 120_000, salvage_cents: 0, useful_life_months: 12)

    expect(asset.monthly_depreciation_cents).to eq(10_000)
  end

  it "never depreciates below salvage value" do
    asset = described_class.new(cost_cents: 100_000, salvage_cents: 150_000, useful_life_months: 12)

    expect(asset.depreciable_cents).to eq(0)
  end
end
end
