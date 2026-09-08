# spec/models/table_config_spec.rb
require 'rails_helper'

RSpec.describe TableConfig, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:category) }
    it { should belong_to(:property_mapping) }
  end

  describe "default attributes" do
    it "has a sensible default for columns_metadata" do
      config = TableConfig.new
      expect(config.columns).to be_an(Array)
      expect(config.columns.first).to include("key" => "name", "name" => "Name")
    end
  end

  describe "columns_metadata validation" do
    subject(:config) { build(:table_config) }

    context "with valid columns_metadata" do
      it "accepts the default columns_metadata" do
        expect(config).to be_valid
      end

      it "accepts a full valid hash array" do
        config.metadata = { "columns" => [
          { "key" => "name", "name" => "Product Name", "visible" => true,
            "width" => 250, "align" => "left" },
          { "key" => "property_integer_1", "name" => "Unit Cost",
            "visible" => true, "width" => 120, "align" => "right" }
        ] }
        expect(config).to be_valid
      end

      it "accepts an empty array" do
        config.metadata = { "columns" => [] }
        expect(config).to be_valid
      end
    end

    context "with invalid root type" do
      it "rejects a non-array value" do
        config.metadata = { "columns" => "not an array" }
        expect(config).not_to be_valid
        expect(config.errors[:metadata]).to include("columns must be an array")
      end
    end

    context "with invalid element types" do
      it "rejects when an element is not a hash" do
        config.metadata = { "columns" => [ "just a string" ] }
        expect(config).not_to be_valid
        expect(config.errors[:metadata]).to include(match(/element 0 must be a hash/))
      end
    end

    context "with missing or blank key" do
      it "rejects when key is missing" do
        config.metadata = { "columns" => [ { "name" => "No Key" } ] }
        expect(config).not_to be_valid
        expect(config.errors[:metadata]).to include(match(/key is required/))
      end

      it "rejects when key is blank" do
        config.metadata = { "columns" => [ { "key" => "", "name" => "Blank Key" } ] }
        expect(config).not_to be_valid
        expect(config.errors[:metadata]).to include(match(/key is required/))
      end
    end

    context "with missing or blank name" do
      it "rejects when name is missing" do
        config.metadata = { "columns" => [ { "key" => "name" } ] }
        expect(config).not_to be_valid
        expect(config.errors[:metadata]).to include(match(/name is required/))
      end

      it "rejects when name is blank" do
        config.metadata = { "columns" => [ { "key" => "name", "name" => "" } ] }
        expect(config).not_to be_valid
        expect(config.errors[:metadata]).to include(match(/name is required/))
      end
    end

    context "with invalid column property types" do
      it "rejects visible when not boolean" do
        config.metadata = { "columns" => [ { "key" => "name", "name" => "N", "visible" => "yes" } ] }
        expect(config).not_to be_valid
        expect(config.errors[:metadata]).to include(match(/visible must be a boolean/))
      end

      it "rejects align with invalid value" do
        config.metadata = { "columns" => [ { "key" => "name", "name" => "N", "align" => "top" } ] }
        expect(config).not_to be_valid
        expect(config.errors[:metadata]).to include(match(/align/))
      end

      it "accepts align as left, center, or right" do
        %w[left center right].each do |val|
          config.metadata = { "columns" => [ { "key" => "name", "name" => "N", "align" => val } ] }
          expect(config).to be_valid
        end
      end

      it "rejects width when not an integer" do
        config.metadata = { "columns" => [ { "key" => "name", "name" => "N", "width" => "auto" } ] }
        expect(config).not_to be_valid
        expect(config.errors[:metadata]).to include(match(/width must be an integer/))
      end

      it "accepts width as nil" do
        config.metadata = { "columns" => [ { "key" => "name", "name" => "N", "width" => nil } ] }
        expect(config).to be_valid
      end

      it "accepts width as an integer" do
        config.metadata = { "columns" => [ { "key" => "name", "name" => "N", "width" => 250 } ] }
        expect(config).to be_valid
      end
    end
  end
  describe "search/filter column settings" do
    subject(:config) { build(:table_config) }

    def with_column(col)
      config.metadata = { "columns" => [
        { "key" => "name", "name" => "Name", "visible" => true }, col
      ] }
      config
    end

    it "accepts search: true on a property_string column" do
      expect(with_column({ "key" => "property_string_1", "name" => "Color", "visible" => true, "search" => true })).to be_valid
    end

    it "accepts search: false on any column" do
      expect(with_column({ "key" => "property_integer_1", "name" => "Qty", "visible" => true, "search" => false })).to be_valid
    end

    it "rejects search: true on a non-string column" do
      expect(with_column({ "key" => "property_integer_1", "name" => "Qty", "visible" => true, "search" => true })).not_to be_valid
      expect(config.errors[:metadata].join).to match(/search is only allowed on string columns/)
    end

    it "rejects non-boolean search" do
      expect(with_column({ "key" => "name", "name" => "Name", "visible" => true, "search" => "yes" })).not_to be_valid
    end

    it "accepts a valid range filter on an integer column" do
      col = { "key" => "property_integer_1", "name" => "Qty", "visible" => true,
              "filter" => { "type" => "range", "active" => true, "buckets" => [ [ nil, 100 ], [ 100, 500 ], [ 500, nil ] ] } }
      expect(with_column(col)).to be_valid
    end

    it "rejects range with an empty or malformed buckets array" do
      expect(with_column({ "key" => "property_integer_1", "name" => "Qty", "visible" => true,
                           "filter" => { "type" => "range", "active" => true, "buckets" => [] } })).not_to be_valid
      expect(with_column({ "key" => "property_integer_1", "name" => "Qty", "visible" => true,
                           "filter" => { "type" => "range", "active" => true, "buckets" => [ [ nil, nil ] ] } })).not_to be_valid
      expect(with_column({ "key" => "property_integer_1", "name" => "Qty", "visible" => true,
                           "filter" => { "type" => "range", "active" => true, "buckets" => [ [ 500, 100 ] ] } })).not_to be_valid
    end

    it "rejects range filter on a datetime column" do
      expect(with_column({ "key" => "property_datetime_1", "name" => "Released", "visible" => true,
                           "filter" => { "type" => "range", "active" => true, "buckets" => [ [ 2024, 2025 ] ] } })).not_to be_valid
    end

    it "accepts date (year) buckets on a datetime column" do
      expect(with_column({ "key" => "property_datetime_1", "name" => "Released", "visible" => true,
                           "filter" => { "type" => "date", "active" => true, "buckets" => [ [ nil, 2024 ], [ 2024, 2025 ], [ 2025, nil ] ] } })).to be_valid
    end

    it "rejects date buckets with non-integer years" do
      expect(with_column({ "key" => "property_datetime_1", "name" => "Released", "visible" => true,
                           "filter" => { "type" => "date", "active" => true, "buckets" => [ [ "2024a", 2025 ] ] } })).not_to be_valid
    end

    it "accepts boolean filter with a label style" do
      expect(with_column({ "key" => "property_boolean_1", "name" => "Active", "visible" => true,
                           "filter" => { "type" => "boolean", "active" => true, "true_false" => true, "yes_no" => false } })).to be_valid
    end

    it "rejects boolean filter without a label style" do
      expect(with_column({ "key" => "property_boolean_1", "name" => "Active", "visible" => true,
                           "filter" => { "type" => "boolean", "active" => true } })).not_to be_valid
    end

    it "rejects boolean filter on a non-boolean column" do
      expect(with_column({ "key" => "property_string_1", "name" => "Color", "visible" => true,
                           "filter" => { "type" => "boolean", "active" => true, "yes_no" => true } })).not_to be_valid
    end

    it "accepts enum filter when the PropertyMapping entry is a select" do
      config.property_mapping.properties = [
        { "key" => "property_integer_2", "name" => "Tier", "type" => "integer",
          "input_type" => "select", "options" => [ { "value" => 1, "label" => "Gold" } ] }
      ]
      expect(with_column({ "key" => "property_integer_2", "name" => "Tier", "visible" => true,
                           "filter" => { "type" => "enum", "active" => true } })).to be_valid
    end

    it "rejects enum filter without a PM select entry" do
      expect(with_column({ "key" => "property_integer_2", "name" => "Tier", "visible" => true,
                           "filter" => { "type" => "enum", "active" => true } })).not_to be_valid
    end

    it "rejects unknown keys inside filter" do
      expect(with_column({ "key" => "property_integer_1", "name" => "Qty", "visible" => true,
                           "filter" => { "type" => "range", "active" => true, "buckets" => [ [ nil, 10 ] ], "extra" => 1 } })).not_to be_valid
    end

    it "rejects a non-hash filter value (e.g. unparsed invalid JSON)" do
      expect(with_column({ "key" => "property_integer_1", "name" => "Qty", "visible" => true,
                           "filter" => '{"type":"range"' })).not_to be_valid
    end

    it "rejects a filter hash without an explicit active key" do
      config.metadata = { "columns" => [
        { "key" => "property_integer_1", "name" => "Qty", "visible" => true,
          "filter" => { "type" => "range", "buckets" => [ [ nil, 10 ] ] } }
      ] }
      expect(config).not_to be_valid
      expect(config.errors[:metadata].join).to match(/filter requires "active" true or false/)
    end

    it "rejects a non-boolean active value" do
      config.metadata = { "columns" => [
        { "key" => "property_integer_1", "name" => "Qty", "visible" => true,
          "filter" => { "type" => "range", "active" => "yes", "buckets" => [ [ nil, 10 ] ] } }
      ] }
      expect(config).not_to be_valid
    end

    it "accepts an explicit active: false (filter stored but disabled)" do
      config.metadata = { "columns" => [
        { "key" => "property_integer_1", "name" => "Qty", "visible" => true,
          "filter" => { "type" => "range", "active" => false, "buckets" => [ [ nil, 10 ] ] } }
      ] }
      expect(config).to be_valid
    end

    it "accepts configs without search/filter keys (old pattern)" do
      expect(with_column({ "key" => "property_string_1", "name" => "Color", "visible" => true })).to be_valid
    end
  end

  it_behaves_like "property_mapping concern", TableConfig
end
