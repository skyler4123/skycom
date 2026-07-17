# frozen_string_literal: true

require "rails_helper"

RSpec.describe DynamicValidationConcern do
  let(:company) { create(:company) }
  let(:category) { create(:category, company: company, resource_name: "products") }
  let(:property_mapping) { category.default_property_mapping }

  let(:product) do
    build(:product, company: company, category: category, property_mapping: property_mapping)
  end

  before do
    property_mapping.update!(metadata: { "properties" => [
      { "key" => "property_string_1", "type" => "string", "name" => "Brand",
        "validates" => { "presence" => true, "length" => { "minimum" => 2, "maximum" => 50 } } },
      { "key" => "property_string_2", "type" => "string", "name" => "SKU Code",
        "validates" => { "format" => { "with" => "^SKU-" } } },
      { "key" => "property_integer_1", "type" => "integer", "name" => "Quantity",
        "validates" => { "numericality" => { "greater_than_or_equal_to" => 0, "less_than" => 10000 } } },
      { "key" => "property_decimal_1", "type" => "decimal", "name" => "Price",
        "validates" => { "numericality" => { "greater_than_or_equal_to" => 0 } } },
      { "key" => "property_boolean_1", "type" => "boolean", "name" => "Active",
        "validates" => { "inclusion" => { "in" => [ true, false ] } } },
      { "key" => "property_text_1", "type" => "text", "name" => "Notes",
        "validates" => {} },
      { "key" => "property_decimal_2", "type" => "decimal", "name" => "Discount",
        "validates" => { "numericality" => { "only_integer" => true, "greater_than_or_equal_to" => 0, "less_than_or_equal_to" => 100 } } }
    ] })
  end

  def fill_baseline
    product.property_string_1 = "BrandName"
    product.property_string_2 = "SKU-001"
    product.property_integer_1 = 10
    product.property_decimal_1 = 5.0
    product.property_decimal_2 = 3
    product.property_boolean_1 = true
    product.property_text_1 = "notes"
  end

  describe "presence" do
    it "adds error when value is blank" do
      fill_baseline
      product.property_string_1 = ""
      product.valid?
      expect(product.errors[:property_string_1]).to include("can't be blank")
    end

    it "is valid when value is present" do
      product.property_string_1 = "Acme"
      product.valid?
      expect(product.errors[:property_string_1]).to be_blank
    end
  end

  describe "numericality" do
    it "adds error when not an integer with only_integer" do
      product.property_decimal_2 = 1.5
      product.valid?
      expect(product.errors[:property_decimal_2]).to include("must be an integer")
    end

    it "adds error when below greater_than_or_equal_to threshold" do
      product.property_integer_1 = -1
      product.valid?
      expect(product.errors[:property_integer_1]).to include("must be greater than or equal to 0")
    end

    it "passes when value equals greater_than_or_equal_to threshold" do
      product.property_integer_1 = 0
      product.valid?
      expect(product.errors[:property_integer_1]).to be_blank
    end

    it "adds error when exceeding less_than threshold" do
      product.property_integer_1 = 10000
      product.valid?
      expect(product.errors[:property_integer_1]).to include("must be less than 10000")
    end

    it "is valid for an integer within range" do
      product.property_integer_1 = 42
      product.valid?
      expect(product.errors[:property_integer_1]).to be_blank
    end

    it "adds error when decimal is negative" do
      product.property_decimal_1 = -0.01
      product.valid?
      expect(product.errors[:property_decimal_1]).to include("must be greater than or equal to 0")
    end

    it "is valid for a positive decimal" do
      product.property_decimal_1 = 19.99
      product.valid?
      expect(product.errors[:property_decimal_1]).to be_blank
    end

    it "adds error when decimal exceeds less_than_or_equal_to" do
      product.property_decimal_2 = 101
      product.valid?
      expect(product.errors[:property_decimal_2]).to include("must be less than or equal to 100")
    end

    it "adds error for nil value (must use allow_nil: true to permit nil)" do
      fill_baseline
      product.property_integer_1 = nil
      product.valid?
      expect(product.errors[:property_integer_1]).to include("is not a number")
    end
  end

  describe "inclusion" do
    it "adds error when value is not in the list" do
      fill_baseline
      product.property_boolean_1 = nil
      product.valid?
      expect(product.errors[:property_boolean_1]).to include("is not included in the list")
    end

    it "is valid when value is in the list" do
      product.property_boolean_1 = true
      product.valid?
      expect(product.errors[:property_boolean_1]).to be_blank
    end
  end

  describe "format" do
    it "adds error when value does not match regex" do
      product.property_string_2 = "INVALID"
      product.valid?
      expect(product.errors[:property_string_2]).to include("is invalid")
    end

    it "is valid when value matches regex" do
      product.property_string_2 = "SKU-12345"
      product.valid?
      expect(product.errors[:property_string_2]).to be_blank
    end
  end

  describe "length" do
    it "adds error when value is shorter than minimum" do
      product.property_string_1 = "A"
      product.valid?
      expect(product.errors[:property_string_1]).to include(/too short/)
    end

    it "adds error when value exceeds maximum" do
      product.property_string_1 = "A" * 51
      product.valid?
      expect(product.errors[:property_string_1]).to include(/too long/)
    end
  end

  describe "empty validates hash" do
    it "skips validation for entries with {} validates" do
      product.property_text_1 = ""
      product.valid?
      expect(product.errors[:property_text_1]).to be_blank
    end
  end

  describe "missing property_mapping" do
    it "does not error when property_mapping is nil" do
      record = build(:product, company: company, category: nil, property_mapping: nil)
      expect { record.valid? }.not_to raise_error
    end
  end
end
