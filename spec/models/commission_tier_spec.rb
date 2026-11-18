# spec/models/commission_tier_spec.rb
require "rails_helper"

RSpec.describe CommissionTier, type: :model do
  describe "table" do
    it "uses commission_tiers" do
      expect(described_class.table_name).to eq("commission_tiers")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:commission_plan) }
  end

  describe "validations" do
    it { should validate_numericality_of(:from_cents).only_integer.is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:to_cents).only_integer.is_greater_than(0).allow_nil }
  end

describe "#covers_cents?" do
  it "covers amounts inside the bracket" do
    tier = described_class.new(from_cents: 1_000, to_cents: 5_000)

    expect(tier.covers_cents?(1_000)).to be(true)
    expect(tier.covers_cents?(4_999)).to be(true)
    expect(tier.covers_cents?(5_000)).to be(false)
  end

  it "treats an open upper bound as unlimited" do
    tier = described_class.new(from_cents: 5_000, to_cents: nil)

    expect(tier.covers_cents?(99_000_000)).to be(true)
  end
end
end
