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

  describe "after_update :sync_table_configs" do
    let(:property_mapping) { create(:property_mapping) }
    let(:table_config) { property_mapping.default_table_config }

    before do
      property_mapping.update!(property_metadata: [
        { "key" => "property_string_1", "type" => "string", "name" => "Brand" },
        { "key" => "property_integer_1", "type" => "integer", "name" => "Quantity" }
      ])
      table_config.update!(columns_metadata: [
        { "key" => "name", "name" => "Name", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
        { "key" => "property_string_1", "name" => "Brand", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
        { "key" => "property_integer_1", "name" => "Quantity", "visible" => true, "sortable" => true, "align" => "right", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} }
      ])
    end

    it "adds a new column when a property is added" do
      property_mapping.update!(property_metadata: [
        { "key" => "property_string_1", "type" => "string", "name" => "Brand" },
        { "key" => "property_integer_1", "type" => "integer", "name" => "Quantity" },
        { "key" => "property_boolean_1", "type" => "boolean", "name" => "Active" }
      ])

      table_config.reload
      keys = table_config.columns_metadata.map { |c| c["key"] }
      expect(keys).to include("property_boolean_1")
      new_col = table_config.columns_metadata.find { |c| c["key"] == "property_boolean_1" }
      expect(new_col["name"]).to eq("Active")
    end

    it "updates column name when a property is renamed" do
      property_mapping.update!(property_metadata: [
        { "key" => "property_string_1", "type" => "string", "name" => "Brand Name" },
        { "key" => "property_integer_1", "type" => "integer", "name" => "Quantity" }
      ])

      table_config.reload
      col = table_config.columns_metadata.find { |c| c["key"] == "property_string_1" }
      expect(col["name"]).to eq("Brand Name")
    end

    it "removes column when a property is deleted" do
      property_mapping.update!(property_metadata: [
        { "key" => "property_string_1", "type" => "string", "name" => "Brand" }
      ])

      table_config.reload
      keys = table_config.columns_metadata.map { |c| c["key"] }
      expect(keys).not_to include("property_integer_1")
    end

    it "does not affect non-property columns" do
      property_mapping.update!(property_metadata: [
        { "key" => "property_string_1", "type" => "string", "name" => "Brand" }
      ])

      table_config.reload
      expect(table_config.columns_metadata.map { |c| c["key"] }).to include("name")
    end

    it "syncs all associated table configs" do
      tc2 = TableConfig.create!(company: property_mapping.company, category: property_mapping.category, property_mapping: property_mapping)

      property_mapping.update!(property_metadata: [
        { "key" => "property_string_1", "type" => "string", "name" => "Brand" },
        { "key" => "property_boolean_1", "type" => "boolean", "name" => "Active" }
      ])

      tc2.reload
      expect(tc2.columns_metadata.map { |c| c["key"] }).to include("property_boolean_1")
    end

    it "does not trigger when property_metadata has not changed" do
      expect(property_mapping).not_to receive(:sync_table_configs)
      property_mapping.update!(name: "New name")
    end
  end
end
