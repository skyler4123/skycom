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
        expect(tc.columns).to eq([])
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

  describe "defined properties (StandardPropertiesConcern)" do
    let(:products_category) do
      create(:category, name: "Cosmetics") { |c| c.update!(resource_name: "products") }
    end

    def products_pm
      products_category.default_property_mapping.tap { |pm| pm.update!(resource_name: "products") }
    end

    describe ".defined_property_entries" do
      it "returns entry hashes for the resource's standard set" do
        keys = PropertyMapping.defined_property_entries("products").map { |e| e["key"] }
        expect(keys).to contain_exactly("name", "description", "code", "workflow_status")
      end

      it "returns [] for an unknown resource" do
        expect(PropertyMapping.defined_property_entries("space_widgets")).to eq([])
      end

      it "returns [] for a resource whose model does not include the concern" do
        expect(PropertyMapping.defined_property_entries("stocks")).to eq([])
      end
    end

    describe "merge on create/update" do
      it "auto-adds defined entries to a property mapping" do
        pm = products_pm
        keys = pm.reload.properties.map { |p| p["key"] }
        expect(keys).to include("name", "code", "workflow_status")
        name_entry = pm.properties.find { |p| p["key"] == "name" }
        expect(name_entry["name"]).to eq("Name")
        expect(name_entry["type"]).to eq("string")
        expect(name_entry["defined"]).to be(true)
      end

      it "restores a renamed defined key from the constant" do
        pm = products_pm
        pm.update!(properties: pm.properties.map { |p| p["key"] == "name" ? p.merge("name" => "Nickname") : p })
        name_entry = pm.reload.properties.find { |p| p["key"] == "name" }
        expect(name_entry["name"]).to eq("Name")
      end
    end

    describe "defined_properties_present" do
      it "errors when defined keys are missing and the merge is bypassed" do
        pm = products_pm
        pm.metadata = { "properties" => [ { "key" => "property_string_2", "type" => "string", "name" => "X" } ] }
        allow(pm).to receive(:merge_defined_properties) # simulate bypassing the merge
        expect(pm).not_to be_valid
        expect(pm.errors[:metadata]).to include(match(/must include defined properties/))
      end
    end

    describe "validate_property_metadata" do
      it "rejects keys that are neither property_* nor defined" do
        pm = products_pm
        pm.properties = pm.properties + [ { "key" => "email", "type" => "string", "name" => "Email" } ]
        expect(pm).not_to be_valid
        expect(pm.errors[:metadata]).to include(match(/not a property_\* slot or defined property/))
      end
    end
  end

  describe "after_update :sync_table_configs" do
    let(:property_mapping) { create(:property_mapping) }
    let(:table_config) { property_mapping.default_table_config }

    before do
      property_mapping.update!(properties: [
        { "key" => "property_string_1", "type" => "string", "name" => "Brand" },
        { "key" => "property_integer_1", "type" => "integer", "name" => "Quantity" }
      ])
      table_config.update!(columns: [
        { "key" => "property_string_1", "name" => "Brand", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
        { "key" => "property_integer_1", "name" => "Quantity", "visible" => true, "sortable" => true, "align" => "right", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} }
      ])
    end

    it "adds a new column when a property is added" do
      property_mapping.update!(properties: [
        { "key" => "property_string_1", "type" => "string", "name" => "Brand" },
        { "key" => "property_integer_1", "type" => "integer", "name" => "Quantity" },
        { "key" => "property_boolean_1", "type" => "boolean", "name" => "Active" }
      ])

      table_config.reload
      keys = table_config.columns.map { |c| c["key"] }
      expect(keys).to include("property_boolean_1")
      new_col = table_config.columns.find { |c| c["key"] == "property_boolean_1" }
      expect(new_col["name"]).to eq("Active")
    end

    it "updates column name when a property is renamed" do
      property_mapping.update!(properties: [
        { "key" => "property_string_1", "type" => "string", "name" => "Brand Name" },
        { "key" => "property_integer_1", "type" => "integer", "name" => "Quantity" }
      ])

      table_config.reload
      col = table_config.columns.find { |c| c["key"] == "property_string_1" }
      expect(col["name"]).to eq("Brand Name")
    end

    it "removes column when a property is deleted" do
      property_mapping.update!(properties: [
        { "key" => "property_string_1", "type" => "string", "name" => "Brand" }
      ])

      table_config.reload
      keys = table_config.columns.map { |c| c["key"] }
      expect(keys).not_to include("property_integer_1")
    end

    it "syncs all associated table configs" do
      tc2 = TableConfig.create!(company: property_mapping.company, category: property_mapping.category, property_mapping: property_mapping)

      property_mapping.update!(properties: [
        { "key" => "property_string_1", "type" => "string", "name" => "Brand" },
        { "key" => "property_boolean_1", "type" => "boolean", "name" => "Active" }
      ])

      tc2.reload
      expect(tc2.columns.map { |c| c["key"] }).to include("property_boolean_1")
    end

    it "does not trigger when property_metadata has not changed" do
      expect(property_mapping).not_to receive(:sync_table_configs)
      property_mapping.update!(name: "New name")
    end
  end
end
