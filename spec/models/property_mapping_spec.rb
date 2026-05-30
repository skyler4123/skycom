# spec/models/property_mapping_spec.rb
require 'rails_helper'

RSpec.describe PropertyMapping, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:category).optional }
  end

  describe "property config validation" do
    let(:mapping) { build(:property_mapping) }

    it "is valid with nil property columns" do
      expect(mapping).to be_valid
    end

    it "is valid with empty hash property columns" do
      mapping.property_string_1 = {}
      mapping.property_integer_5 = {}
      expect(mapping).to be_valid
    end

    it "is valid with a minimal label-only config" do
      mapping.property_string_1 = { "label" => "Color" }
      expect(mapping).to be_valid
    end

    it "is valid with all supported keys for each type" do
      mapping.property_string_1 = { "label" => "Color", "input_type" => "text", "placeholder" => "#FF5733", "suffix" => "", "prefix" => "", "default" => "" }
      mapping.property_text_1 = { "label" => "Notes", "input_type" => "textarea", "placeholder" => "Enter notes", "default" => "" }
      mapping.property_integer_1 = { "label" => "Stock", "min" => 0, "max" => 100, "placeholder" => "0", "suffix" => "units", "prefix" => "", "default" => 0 }
      mapping.property_decimal_1 = { "label" => "Price", "input_type" => "currency", "precision" => 0, "suffix" => "VND", "prefix" => "", "placeholder" => "0", "default" => 0, "currency" => "VND" }
      mapping.property_boolean_1 = { "label" => "Active", "input_type" => "toggle", "suffix" => "", "prefix" => "", "placeholder" => "", "default" => false, "true_label" => "Yes", "false_label" => "No" }
      mapping.property_datetime_1 = { "label" => "Hire Date", "input_type" => "date_only", "suffix" => "", "prefix" => "", "placeholder" => "", "default" => "", "format" => "YYYY-MM-DD", "timezone" => "Asia/Ho_Chi_Minh" }
      expect(mapping).to be_valid
    end

    it "is valid with a select config with valid options" do
      mapping.property_integer_1 = {
        "label" => "Skin Type",
        "input_type" => "select",
        "options" => [
          { "value" => 1, "label" => "Oily" },
          { "value" => 2, "label" => "Dry" }
        ]
      }
      expect(mapping).to be_valid
    end

    it "auto-converts a plain string to a label hash" do
      mapping.property_string_1 = "Skin Type"
      expect(mapping).to be_valid
      expect(mapping.property_string_1).to eq({ "label" => "Skin Type" })
    end

    it "is invalid with a non-hash non-string value" do
      mapping.property_string_1 = [ "array" ]
      expect(mapping).not_to be_valid
      expect(mapping.errors[:property_string_1]).to include("must be a JSON object (Hash)")
    end

    it "is invalid without a label" do
      mapping.property_string_1 = { "input_type" => "text" }
      expect(mapping).not_to be_valid
      expect(mapping.errors[:property_string_1]).to include(match(/label/))
    end

    it "is invalid with a blank label" do
      mapping.property_string_1 = { "label" => "" }
      expect(mapping).not_to be_valid
      expect(mapping.errors[:property_string_1]).to include(match(/label/))
    end

    it "is invalid when input_type doesn't match the column prefix" do
      mapping.property_string_1 = { "label" => "Bad", "input_type" => "currency" }
      expect(mapping).not_to be_valid
      expect(mapping.errors[:property_string_1]).to include(match(/input_type.*must be one of/))
    end

    it "is invalid when select is missing options" do
      mapping.property_integer_1 = { "label" => "Type", "input_type" => "select" }
      expect(mapping).not_to be_valid
      expect(mapping.errors[:property_integer_1]).to include(match(/options/))
    end

    it "is invalid when select options have wrong structure" do
      mapping.property_integer_1 = {
        "label" => "Type",
        "input_type" => "select",
        "options" => [ "just", "strings" ]
      }
      expect(mapping).not_to be_valid
      expect(mapping.errors[:property_integer_1]).to include(match(/options/))
    end

    it "rejects unsupported keys on string columns" do
      mapping.property_string_1 = { "label" => "Test", "precision" => 2 }
      expect(mapping).not_to be_valid
      expect(mapping.errors[:property_string_1]).to include(match(/unsupported key/))
    end

    it "rejects unsupported keys on text columns" do
      mapping.property_text_1 = { "label" => "Test", "max" => 10 }
      expect(mapping).not_to be_valid
      expect(mapping.errors[:property_text_1]).to include(match(/unsupported key/))
    end

    it "rejects unsupported keys on integer columns" do
      mapping.property_integer_1 = { "label" => "Test", "currency" => "VND" }
      expect(mapping).not_to be_valid
      expect(mapping.errors[:property_integer_1]).to include(match(/unsupported key/))
    end

    it "rejects unsupported keys on decimal columns" do
      mapping.property_decimal_1 = { "label" => "Test", "options" => [] }
      expect(mapping).not_to be_valid
      expect(mapping.errors[:property_decimal_1]).to include(match(/unsupported key/))
    end

    it "rejects unsupported keys on boolean columns" do
      mapping.property_boolean_1 = { "label" => "Test", "format" => "checkbox" }
      expect(mapping).not_to be_valid
      expect(mapping.errors[:property_boolean_1]).to include(match(/unsupported key/))
    end

    it "rejects unsupported keys on datetime columns" do
      mapping.property_datetime_1 = { "label" => "Test", "options" => [] }
      expect(mapping).not_to be_valid
      expect(mapping.errors[:property_datetime_1]).to include(match(/unsupported key/))
    end

    it "can accumulate errors on multiple columns" do
      mapping.property_string_1 = { "input_type" => "currency" }
      mapping.property_integer_1 = { "label" => "Type", "input_type" => "select" }
      expect(mapping).not_to be_valid
      expect(mapping.errors[:property_string_1]).to be_present
      expect(mapping.errors[:property_integer_1]).to be_present
    end

    it "is valid with all documented input_types for each prefix" do
      all_configs = {
        property_string_1:  { "label" => "A", "input_type" => "text" },
        property_text_1:    { "label" => "B", "input_type" => "textarea" },
        property_integer_1: { "label" => "C", "input_type" => "select", "options" => [ { "value" => 1, "label" => "X" } ] },
        property_integer_2: { "label" => "D", "input_type" => "progress_bar" },
        property_integer_3: { "label" => "E", "input_type" => "slider" },
        property_integer_4: { "label" => "F", "input_type" => "star" },
        property_decimal_1: { "label" => "G", "input_type" => "currency", "currency" => "USD" },
        property_decimal_2: { "label" => "H", "input_type" => "number" },
        property_decimal_3: { "label" => "I", "input_type" => "percentage" },
        property_boolean_1: { "label" => "J", "input_type" => "toggle" },
        property_datetime_1: { "label" => "K", "input_type" => "date_only" },
        property_datetime_2: { "label" => "L", "input_type" => "datetime" },
        property_datetime_3: { "label" => "M", "input_type" => "relative" }
      }

      mapping.assign_attributes(all_configs)
      expect(mapping).to be_valid
    end
  end
end
