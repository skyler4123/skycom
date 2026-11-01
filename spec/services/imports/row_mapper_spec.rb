# frozen_string_literal: true

require "rails_helper"

RSpec.describe Imports::RowMapper do
  let!(:company) { create(:company) }
  let(:category) { product_import_category(company: company) }
  let(:resolved) { Imports::SchemaResolver.call(company: company, target_table: "products", category: category) }
  let(:schema) { resolved[:schema] }
  let(:model) { resolved[:model] }

  def mapper
    described_class.new(company: company, schema: schema, model: model)
  end

  def map(row)
    mapper.map(row)
  end

  describe "successful casts" do
    it "casts strings, integers, enums, and property slots" do
      brand = create(:brand, company: company)

      result = map(
        "name" => "Serum",
        "business_type" => "physical",
        "price_cents" => "1500",
        "brand_id" => brand.id,
        "Skin Type Suitability" => "Oily",
        "Volume (ml)" => "30"
      )

      expect(result[:errors]).to be_empty
      expect(result[:attrs]).to include(
        "name" => "Serum",
        "business_type" => "physical",
        "price_cents" => 1500,
        "brand_id" => brand.id,
        "property_string_1" => "Oily",
        "property_integer_1" => 30
      )
    end

    it "accepts a numeric enum value" do
      result = map("business_type" => "0")

      expect(result[:errors]).to be_empty
      expect(result[:attrs]["business_type"]).to eq(0)
    end

    it "accepts boolean and datetime property values" do
      bool_category = Seed::CategoryService.create(
        company: company,
        name: "Boolean products #{SecureRandom.hex(3)}",
        resource_name: "products",
        properties: { property_boolean_1: "Is Featured", property_datetime_1: "Available From" }
      )
      resolver = Imports::SchemaResolver.call(company: company, target_table: "products", category: bool_category)
      map_result = described_class.new(company: company, schema: resolver[:schema], model: resolver[:model]).map(
        "business_type" => "physical",
        "Is Featured" => "yes",
        "Available From" => "2026-11-01 10:30"
      )

      expect(map_result[:errors]).to be_empty
      expect(map_result[:attrs]["property_boolean_1"]).to be(true)
      expect(map_result[:attrs]["property_datetime_1"]).to be_a(Time)
    end

    it "omits blank cells instead of writing empty strings" do
      result = map("name" => "", "business_type" => "physical")

      expect(result[:errors]).to be_empty
      expect(result[:attrs]).to eq("business_type" => "physical")
    end
  end

  describe "failures" do
    it "reports an unparsable integer" do
      result = map("price_cents" => "12.5")

      expect(result[:errors]).to include("price_cents: cannot parse '12.5'")
    end

    it "reports an unparsable property integer" do
      result = map("Volume (ml)" => "abc")

      expect(result[:errors]).to include("Volume (ml): cannot parse 'abc'")
    end

    it "reports an invalid boolean" do
      bool_category = Seed::CategoryService.create(
        company: company,
        name: "Boolean failures #{SecureRandom.hex(3)}",
        resource_name: "products",
        properties: { property_boolean_1: "Is Featured" }
      )
      resolver = Imports::SchemaResolver.call(company: company, target_table: "products", category: bool_category)
      result = described_class.new(company: company, schema: resolver[:schema], model: resolver[:model]).map(
        "Is Featured" => "maybe"
      )

      expect(result[:errors].first).to match(/is not a boolean/)
    end

    it "reports an invalid enum label" do
      result = map("business_type" => "spaceship")

      expect(result[:errors].first).to match(/is not a valid value/)
    end

    it "reports a malformed UUID" do
      result = map("brand_id" => "not-a-uuid")

      expect(result[:errors]).to include("brand_id: cannot parse 'not-a-uuid'")
    end

    it "reports a missing association record in the same company" do
      result = map("brand_id" => SecureRandom.uuid)

      expect(result[:errors]).to include("brand_id: no record found in this company")
    end

    it "rejects a foreign key from another company" do
      other_brand = create(:brand, company: create(:company))

      result = map("brand_id" => other_brand.id)

      expect(result[:errors]).to include("brand_id: no record found in this company")
    end
  end
end
