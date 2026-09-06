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
  it_behaves_like "property_mapping concern", TableConfig
end
