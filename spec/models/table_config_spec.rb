# spec/models/table_config_spec.rb
require 'rails_helper'

RSpec.describe TableConfig, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:category) }
  end

  describe "default attributes" do
    it "has a sensible default for fields" do
      config = TableConfig.new
      expect(config.fields).to be_an(Array)
      expect(config.fields.first).to include("key" => "name", "label" => "Name")
    end
  end

  describe "fields validation" do
    subject(:config) { build(:table_config) }

    context "with valid fields" do
      it "accepts the default fields" do
        expect(config).to be_valid
      end

      it "accepts a full valid hash array" do
        config.fields = [
          { "key" => "name", "label" => "Product Name", "visible" => true,
            "width" => 250, "align" => "left", "pinned" => "left",
            "sortable" => true, "roles" => [ "admin", "manager" ],
            "is_virtual" => false, "render_config" => {} },
          { "key" => "property_integer_1", "label" => "Unit Cost",
            "visible" => true, "width" => 120, "align" => "right",
            "sortable" => true, "roles" => [], "is_virtual" => false,
            "render_config" => { "format" => "currency" } }
        ]
        expect(config).to be_valid
      end

      it "accepts an empty array" do
        config.fields = []
        expect(config).to be_valid
      end
    end

    context "with invalid root type" do
      it "rejects a non-array value" do
        config.fields = "not an array"
        expect(config).not_to be_valid
        expect(config.errors[:fields]).to include("must be an array")
      end
    end

    context "with invalid element types" do
      it "rejects when an element is not a hash" do
        config.fields = [ "just a string" ]
        expect(config).not_to be_valid
        expect(config.errors[:fields]).to include(match(/element 0 must be a hash/))
      end
    end

    context "with missing or blank key" do
      it "rejects when key is missing" do
        config.fields = [ { "label" => "No Key" } ]
        expect(config).not_to be_valid
        expect(config.errors[:fields]).to include(match(/key is required/))
      end

      it "rejects when key is blank" do
        config.fields = [ { "key" => "", "label" => "Blank Key" } ]
        expect(config).not_to be_valid
        expect(config.errors[:fields]).to include(match(/key is required/))
      end
    end

    context "with missing or blank label" do
      it "rejects when label is missing" do
        config.fields = [ { "key" => "name" } ]
        expect(config).not_to be_valid
        expect(config.errors[:fields]).to include(match(/label is required/))
      end

      it "rejects when label is blank" do
        config.fields = [ { "key" => "name", "label" => "" } ]
        expect(config).not_to be_valid
        expect(config.errors[:fields]).to include(match(/label is required/))
      end
    end

    context "with invalid field property types" do
      it "rejects visible when not boolean" do
        config.fields = [ { "key" => "name", "label" => "N", "visible" => "yes" } ]
        expect(config).not_to be_valid
        expect(config.errors[:fields]).to include(match(/visible must be a boolean/))
      end

      it "rejects sortable when not boolean" do
        config.fields = [ { "key" => "name", "label" => "N", "sortable" => "yes" } ]
        expect(config).not_to be_valid
        expect(config.errors[:fields]).to include(match(/sortable must be a boolean/))
      end

      it "rejects is_virtual when not boolean" do
        config.fields = [ { "key" => "name", "label" => "N", "is_virtual" => "yes" } ]
        expect(config).not_to be_valid
        expect(config.errors[:fields]).to include(match(/is_virtual must be a boolean/))
      end

      it "rejects align with invalid value" do
        config.fields = [ { "key" => "name", "label" => "N", "align" => "top" } ]
        expect(config).not_to be_valid
        expect(config.errors[:fields]).to include(match(/align/))
      end

      it "accepts align as left, center, or right" do
        %w[left center right].each do |val|
          config.fields = [ { "key" => "name", "label" => "N", "align" => val } ]
          expect(config).to be_valid
        end
      end

      it "rejects pinned with invalid value" do
        config.fields = [ { "key" => "name", "label" => "N", "pinned" => "top" } ]
        expect(config).not_to be_valid
        expect(config.errors[:fields]).to include(match(/pinned/))
      end

      it "accepts pinned as left, right, or nil" do
        [ "left", "right" ].each do |val|
          config.fields = [ { "key" => "name", "label" => "N", "pinned" => val } ]
          expect(config).to be_valid
        end
        config.fields = [ { "key" => "name", "label" => "N", "pinned" => nil } ]
        expect(config).to be_valid
      end

      it "rejects width when not an integer" do
        config.fields = [ { "key" => "name", "label" => "N", "width" => "auto" } ]
        expect(config).not_to be_valid
        expect(config.errors[:fields]).to include(match(/width must be an integer/))
      end

      it "accepts width as nil" do
        config.fields = [ { "key" => "name", "label" => "N", "width" => nil } ]
        expect(config).to be_valid
      end

      it "accepts width as an integer" do
        config.fields = [ { "key" => "name", "label" => "N", "width" => 250 } ]
        expect(config).to be_valid
      end

      it "rejects roles when not an array of strings" do
        config.fields = [ { "key" => "name", "label" => "N", "roles" => "admin" } ]
        expect(config).not_to be_valid
        expect(config.errors[:fields]).to include(match(/roles/))
      end

      it "accepts roles as nil" do
        config.fields = [ { "key" => "name", "label" => "N", "roles" => nil } ]
        expect(config).to be_valid
      end

      it "rejects render_config when not a hash" do
        config.fields = [ { "key" => "name", "label" => "N", "render_config" => "string" } ]
        expect(config).not_to be_valid
        expect(config.errors[:fields]).to include(match(/render_config must be a hash/))
      end

      it "accepts render_config as nil" do
        config.fields = [ { "key" => "name", "label" => "N", "render_config" => nil } ]
        expect(config).to be_valid
      end
    end
  end
end
