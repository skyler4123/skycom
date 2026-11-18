# spec/models/storage_location_spec.rb
require "rails_helper"

RSpec.describe StorageLocation, type: :model do
  describe "table" do
    it "uses storage_locations" do
      expect(described_class.table_name).to eq("storage_locations")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:warehouse) }
    it { should belong_to(:parent).class_name("StorageLocation").optional }
    it { should have_many(:children).class_name("StorageLocation").dependent(:restrict_with_error) }
    it { should have_many(:stock_serials).dependent(:nullify) }
    it { should have_many(:pick_tasks).dependent(:nullify) }
  end

  describe "validations" do
    it { should validate_presence_of(:code) }
    it { should validate_length_of(:code).is_at_most(32) }
    it "declares code uniqueness scoped to warehouse_id" do
      validator = described_class.validators_on(:code).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[warehouse_id])
    end
  end

  describe "enums" do
    it { should define_enum_for(:location_type).with_prefix(true).with_values(zone: 0, aisle: 1, rack: 2, bin: 3) }
  end
end
