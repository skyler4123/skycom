# spec/models/property_mapping_spec.rb
require 'rails_helper'

RSpec.describe PropertyMapping, type: :model do
  describe "callbacks" do
    describe "after_create :create_default_table_config" do
      it "auto-creates a default TableConfig on creation" do
        property_mapping = create(:property_mapping)

        expect(property_mapping.table_configs.reload).to be_present
        expect(property_mapping.table_configs.count).to eq(1)
        expect(property_mapping.table_configs.first.company).to eq(property_mapping.company)
        expect(property_mapping.table_configs.first.category).to eq(property_mapping.category)
        expect(property_mapping.table_configs.first.property_mapping).to eq(property_mapping)
      end

      it "creates a TableConfig with default columns_metadata" do
        property_mapping = create(:property_mapping)

        tc = property_mapping.table_configs.first
        expect(tc.columns_metadata).to be_present
        expect(tc.columns_metadata).to be_an(Array)
        expect(tc.columns_metadata.first["key"]).to eq("name")
      end
    end
  end

  describe "validations" do
    describe "must_have_table_config" do
      it "is valid when table_config exists" do
        property_mapping = create(:property_mapping)
        expect(property_mapping).to be_valid
      end

      it "adds an error when no table_config exists on update" do
        property_mapping = create(:property_mapping)
        property_mapping.table_configs.destroy_all
        property_mapping.reload

        expect(property_mapping).not_to be_valid
        expect(property_mapping.errors[:base]).to include("must have at least one table config")
      end
    end
  end
end
