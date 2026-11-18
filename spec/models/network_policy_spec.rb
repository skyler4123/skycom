# spec/models/network_policy_spec.rb
require "rails_helper"

RSpec.describe NetworkPolicy, type: :model do
  describe "table" do
    it "uses network_policies" do
      expect(described_class.table_name).to eq("network_policies")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
  end

  describe "validations" do
    it { should validate_presence_of(:cidr) }
    it { should validate_length_of(:cidr).is_at_most(64) }
  end

  describe "enums" do
    it { should define_enum_for(:scope).with_prefix(true).with_values(all: 0, finance: 1, hr: 2, admin: 3) }
  end

describe "CIDR" do
  it "rejects a value that is not an IP or CIDR block" do
    policy = described_class.new(cidr: "not-an-ip")
    policy.valid?

    expect(policy.errors[:cidr]).to include("must be a valid IP address or CIDR block")
  end

  it "accepts a CIDR block" do
    policy = described_class.new(cidr: "10.0.0.0/8")
    policy.valid?

    expect(policy.errors[:cidr]).to eq([])
  end
end
end
