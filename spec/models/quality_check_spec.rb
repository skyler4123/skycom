# spec/models/quality_check_spec.rb
require "rails_helper"

RSpec.describe QualityCheck, type: :model do
  describe "table" do
    it "uses quality_checks" do
      expect(described_class.table_name).to eq("quality_checks")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:quality_inspection) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
  end

  describe "enums" do
    it { should define_enum_for(:result).with_prefix(true).with_values(pass: 0, fail: 1, conditional: 2) }
  end

describe "#within_bounds?" do
  it "accepts a measurement inside the bounds" do
    check = described_class.new(min_value: 1, max_value: 5, measured_value: 3)

    expect(check).to be_within_bounds
  end

  it "rejects a measurement outside the bounds" do
    check = described_class.new(min_value: 1, max_value: 5, measured_value: 8)

    expect(check).not_to be_within_bounds
  end
end
end
