# spec/models/loyalty_entry_spec.rb
require "rails_helper"

RSpec.describe LoyaltyEntry, type: :model do
  describe "table" do
    it "uses loyalty_entries" do
      expect(described_class.table_name).to eq("loyalty_entries")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:customer) }
    it { should belong_to(:loyalty_program) }
    it { should belong_to(:source).optional }
  end

  describe "validations" do
    it { should validate_numericality_of(:points).only_integer }
  end

  describe "enums" do
    it { should define_enum_for(:direction).with_prefix(true).with_values(earn: 0, redeem: 1, expire: 2, adjust: 3) }
  end
end
