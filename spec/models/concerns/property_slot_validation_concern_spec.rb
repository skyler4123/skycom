# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Property slot type validation" do
  let(:company) { create(:company) }
  let(:category) { create(:category, company: company, resource_name: "products") }
  let(:property_mapping) { category.default_property_mapping }

  let(:product) do
    build(:product, company: company, category: category, property_mapping: property_mapping).tap do |record|
      record.skip_property_auto_population = true
    end
  end

  before do
    property_mapping.update!(metadata: { "properties" => [
      { "key" => "property_string_1", "type" => "string", "name" => "Brand" },
      { "key" => "property_integer_1", "type" => "integer", "name" => "Quantity" },
      { "key" => "property_decimal_1", "type" => "decimal", "name" => "Price" },
      { "key" => "property_boolean_1", "type" => "boolean", "name" => "Active" },
      { "key" => "property_datetime_1", "type" => "datetime", "name" => "Released At" }
    ] })
  end

  describe "string slots" do
    it "accepts a value at the 255 character limit" do
      product.property_string_1 = "a" * 255
      product.valid?
      expect(product.errors[:property_string_1]).to be_blank
    end

    it "rejects a value over the 255 character limit" do
      product.property_string_1 = "a" * 256
      product.valid?
      expect(product.errors[:property_string_1]).to include("is too long (maximum is 255 characters)")
    end
  end

  describe "integer slots" do
    it "accepts the 32-bit minimum and maximum" do
      [ -2_147_483_648, 2_147_483_647 ].each do |value|
        product.property_integer_1 = value
        product.valid?
        expect(product.errors[:property_integer_1]).to be_blank
      end
    end

    it "rejects values outside the 32-bit range" do
      product.property_integer_1 = 2_147_483_648
      product.valid?
      expect(product.errors[:property_integer_1]).to include("must be between -2147483648 and 2147483647")
    end
  end

  describe "decimal slots" do
    it "accepts four decimal places" do
      product.property_decimal_1 = 12.3456
      product.valid?
      expect(product.errors[:property_decimal_1]).to be_blank
    end

    it "rejects more than four decimal places" do
      product.property_decimal_1 = 12.34567
      product.valid?
      expect(product.errors[:property_decimal_1]).to include("must have at most 4 decimal places")
    end

    it "accepts the maximum decimal value" do
      product.property_decimal_1 = BigDecimal("99999999999.9999")
      product.valid?
      expect(product.errors[:property_decimal_1]).to be_blank
    end

    it "rejects a decimal above the column maximum" do
      product.property_decimal_1 = BigDecimal("100000000000")
      product.valid?
      expect(product.errors[:property_decimal_1]).to include("must be less than or equal to 99999999999.9999")
    end
  end

  describe "boolean slots" do
    it "accepts true and false" do
      [ true, false ].each do |value|
        product.property_boolean_1 = value
        product.valid?
        expect(product.errors[:property_boolean_1]).to be_blank
      end
    end
  end

  describe "datetime slots" do
    it "accepts a valid datetime" do
      product.property_datetime_1 = Time.zone.parse("2026-01-15 10:30")
      product.valid?
      expect(product.errors[:property_datetime_1]).to be_blank
    end

    it "rejects an invalid datetime value" do
      product.property_datetime_1 = "not-a-date"
      product.valid?
      expect(product.errors[:property_datetime_1]).to include("is not a valid date/time")
    end
  end

  describe "blank values" do
    it "allows every property slot to stay blank" do
      product.valid?
      expect(product.errors[:property_string_1]).to be_blank
      expect(product.errors[:property_integer_1]).to be_blank
      expect(product.errors[:property_decimal_1]).to be_blank
      expect(product.errors[:property_boolean_1]).to be_blank
      expect(product.errors[:property_datetime_1]).to be_blank
    end
  end

  describe "unconfigured slots" do
    it "does not validate a property slot that is not in the mapping" do
      product.property_string_2 = "a" * 500
      product.valid?
      expect(product.errors[:property_string_2]).to be_blank
    end
  end

  describe "auto-population" do
    it "fills blank slots on normal validation" do
      auto_product = build(:product, company: company, category: category, property_mapping: property_mapping)

      auto_product.valid?

      expect(auto_product.property_string_1).to be_present
    end

    it "leaves blank slots empty when the import opt-out is set" do
      product.valid?

      expect(product.property_string_1).to be_nil
    end
  end
end
