# spec/models/brand_profile_spec.rb
require "rails_helper"

RSpec.describe BrandProfile, type: :model do
  describe "table" do
    it "uses brand_profiles" do
      expect(described_class.table_name).to eq("brand_profiles")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:logo_stored_file).class_name("StoredFile").optional }
  end

  describe "validations" do
    it { should validate_presence_of(:domain) }
    it { should validate_length_of(:domain).is_at_most(255) }
    it "declares domain uniqueness scoped to the whole table" do
      validator = described_class.validators_on(:domain).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq([])
    end
  end
end
