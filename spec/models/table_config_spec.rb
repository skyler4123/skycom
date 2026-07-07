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
      expect(config.columns_metadata).to be_an(Array)
      expect(config.columns_metadata.first).to include("key" => "name", "name" => "Name")
    end
  end

  describe "columns_metadata validation" do
    subject(:config) { build(:table_config) }

    context "with valid columns_metadata" do
      it "accepts the default columns_metadata" do
        expect(config).to be_valid
      end

      it "accepts a full valid hash array" do
        config.columns_metadata = [
          { "key" => "name", "name" => "Product Name", "visible" => true,
            "width" => 250, "align" => "left", "pinned" => "left",
            "sortable" => true, "roles" => [ "admin", "manager" ],
            "is_virtual" => false, "render_config" => {} },
          { "key" => "property_integer_1", "name" => "Unit Cost",
            "visible" => true, "width" => 120, "align" => "right",
            "sortable" => true, "roles" => [], "is_virtual" => false,
            "render_config" => { "format" => "currency" } }
        ]
        expect(config).to be_valid
      end

      it "accepts an empty array" do
        config.columns_metadata = []
        expect(config).to be_valid
      end
    end

    context "with invalid root type" do
      it "rejects a non-array value" do
        config.columns_metadata = "not an array"
        expect(config).not_to be_valid
        expect(config.errors[:columns_metadata]).to include("must be an array")
      end
    end

    context "with invalid element types" do
      it "rejects when an element is not a hash" do
        config.columns_metadata = [ "just a string" ]
        expect(config).not_to be_valid
        expect(config.errors[:columns_metadata]).to include(match(/element 0 must be a hash/))
      end
    end

    context "with missing or blank key" do
      it "rejects when key is missing" do
        config.columns_metadata = [ { "name" => "No Key" } ]
        expect(config).not_to be_valid
        expect(config.errors[:columns_metadata]).to include(match(/key is required/))
      end

      it "rejects when key is blank" do
        config.columns_metadata = [ { "key" => "", "name" => "Blank Key" } ]
        expect(config).not_to be_valid
        expect(config.errors[:columns_metadata]).to include(match(/key is required/))
      end
    end

    context "with missing or blank name" do
      it "rejects when name is missing" do
        config.columns_metadata = [ { "key" => "name" } ]
        expect(config).not_to be_valid
        expect(config.errors[:columns_metadata]).to include(match(/name is required/))
      end

      it "rejects when name is blank" do
        config.columns_metadata = [ { "key" => "name", "name" => "" } ]
        expect(config).not_to be_valid
        expect(config.errors[:columns_metadata]).to include(match(/name is required/))
      end
    end

    context "with invalid column property types" do
      it "rejects visible when not boolean" do
        config.columns_metadata = [ { "key" => "name", "name" => "N", "visible" => "yes" } ]
        expect(config).not_to be_valid
        expect(config.errors[:columns_metadata]).to include(match(/visible must be a boolean/))
      end

      it "rejects sortable when not boolean" do
        config.columns_metadata = [ { "key" => "name", "name" => "N", "sortable" => "yes" } ]
        expect(config).not_to be_valid
        expect(config.errors[:columns_metadata]).to include(match(/sortable must be a boolean/))
      end

      it "rejects is_virtual when not boolean" do
        config.columns_metadata = [ { "key" => "name", "name" => "N", "is_virtual" => "yes" } ]
        expect(config).not_to be_valid
        expect(config.errors[:columns_metadata]).to include(match(/is_virtual must be a boolean/))
      end

      it "rejects align with invalid value" do
        config.columns_metadata = [ { "key" => "name", "name" => "N", "align" => "top" } ]
        expect(config).not_to be_valid
        expect(config.errors[:columns_metadata]).to include(match(/align/))
      end

      it "accepts align as left, center, or right" do
        %w[left center right].each do |val|
          config.columns_metadata = [ { "key" => "name", "name" => "N", "align" => val } ]
          expect(config).to be_valid
        end
      end

      it "rejects pinned with invalid value" do
        config.columns_metadata = [ { "key" => "name", "name" => "N", "pinned" => "top" } ]
        expect(config).not_to be_valid
        expect(config.errors[:columns_metadata]).to include(match(/pinned/))
      end

      it "accepts pinned as left, right, or nil" do
        [ "left", "right" ].each do |val|
          config.columns_metadata = [ { "key" => "name", "name" => "N", "pinned" => val } ]
          expect(config).to be_valid
        end
        config.columns_metadata = [ { "key" => "name", "name" => "N", "pinned" => nil } ]
        expect(config).to be_valid
      end

      it "rejects width when not an integer" do
        config.columns_metadata = [ { "key" => "name", "name" => "N", "width" => "auto" } ]
        expect(config).not_to be_valid
        expect(config.errors[:columns_metadata]).to include(match(/width must be an integer/))
      end

      it "accepts width as nil" do
        config.columns_metadata = [ { "key" => "name", "name" => "N", "width" => nil } ]
        expect(config).to be_valid
      end

      it "accepts width as an integer" do
        config.columns_metadata = [ { "key" => "name", "name" => "N", "width" => 250 } ]
        expect(config).to be_valid
      end

      it "rejects roles when not an array of strings" do
        config.columns_metadata = [ { "key" => "name", "name" => "N", "roles" => "admin" } ]
        expect(config).not_to be_valid
        expect(config.errors[:columns_metadata]).to include(match(/roles/))
      end

      it "accepts roles as nil" do
        config.columns_metadata = [ { "key" => "name", "name" => "N", "roles" => nil } ]
        expect(config).to be_valid
      end

      it "rejects render_config when not a hash" do
        config.columns_metadata = [ { "key" => "name", "name" => "N", "render_config" => "string" } ]
        expect(config).not_to be_valid
        expect(config.errors[:columns_metadata]).to include(match(/render_config must be a hash/))
      end

      it "accepts render_config as nil" do
        config.columns_metadata = [ { "key" => "name", "name" => "N", "render_config" => nil } ]
        expect(config).to be_valid
      end
    end
  end
  it_behaves_like "property_mapping concern", TableConfig
end
