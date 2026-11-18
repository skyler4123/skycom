# spec/models/api_key_spec.rb
require "rails_helper"

RSpec.describe ApiKey, type: :model do
  describe "table" do
    it "uses api_keys" do
      expect(described_class.table_name).to eq("api_keys")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:created_by_employee).class_name("Employee").optional }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
    it { should validate_presence_of(:token_digest) }
    it "declares token_digest uniqueness scoped to the whole table" do
      validator = described_class.validators_on(:token_digest).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq([])
    end
  end

describe "#active?" do
  it "is inactive once revoked" do
    expect(described_class.new(name: "key", token_digest: "digest", revoked_at: Time.current)).not_to be_active
  end

  it "is active while unrevoked and unexpired" do
    expect(described_class.new(name: "key", token_digest: "digest")).to be_active
  end
end
end
