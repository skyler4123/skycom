# frozen_string_literal: true

require "rails_helper"

RSpec.describe Imports::SchemaResolver do
  UNSET = Object.new

  let!(:company) { create(:company) }
  let(:category) { product_import_category(company: company) }

  def resolve(target_table: "products", category: UNSET, company: UNSET)
    described_class.call(
      company: company.equal?(UNSET) ? self.company : company,
      target_table: target_table,
      category: category.equal?(UNSET) ? self.category : category
    )
  end

  describe "the resolved contract" do
    it "returns model columns plus the category's property display names" do
      result = resolve

      expect(result[:success]).to be(true)
      headers = result[:schema]["headers"].map { |entry| entry["header"] }

      expect(headers).to include("name", "business_type", "brand_id", "price_cents")
      expect(headers).to include("Skin Type Suitability", "Volume (ml)")
      expect(headers).not_to include("property_string_1", "property_integer_1")
      expect(headers.first).to eq("name")
    end

    it "marks required columns and required property slots" do
      result = resolve
      headers = result[:schema]["headers"].index_by { |entry| entry["header"] }

      expect(headers["name"]["required"]).to be(true)
      expect(headers["business_type"]["required"]).to be(true)
      expect(headers["brand_id"]["required"]).to be(false)
      expect(headers["Skin Type Suitability"]["required"]).to be(true)
    end

    it "exposes enum labels and association metadata" do
      result = resolve
      headers = result[:schema]["headers"].index_by { |entry| entry["header"] }

      expect(headers["business_type"]["type"]).to eq("enum")
      expect(headers["business_type"]["enum"]).to contain_exactly("physical", "digital", "service_based")
      expect(headers["brand_id"]["type"]).to eq("uuid")
      expect(headers["brand_id"]["association"]).to include(
        "model" => "Brand",
        "foreign_key" => "brand_id",
        "company_scoped" => true
      )
    end

    it "excludes engine-owned and json columns" do
      result = resolve
      headers = result[:schema]["headers"].map { |entry| entry["header"] }

      %w[id company_id category_id property_mapping_id created_at updated_at discarded_at
         permission_resource_name metadata].each do |column|
        expect(headers).not_to include(column)
      end
    end

    it "maps property slots to their attribute" do
      result = resolve
      headers = result[:schema]["headers"].index_by { |entry| entry["header"] }

      expect(headers["Skin Type Suitability"]).to include("attribute" => "property_string_1", "kind" => "property")
      expect(headers["name"]).to include("attribute" => "name", "kind" => "column")
    end

    it "is deterministic and changes when the category schema changes" do
      first = resolve[:schema]["digest"]
      second = resolve[:schema]["digest"]

      expect(first).to eq(second)

      category.default_property_mapping.update!(
        metadata: { "properties" => [
          { "key" => "property_string_1", "type" => "string", "name" => "Renamed", "validates" => {} }
        ] }
      )

      expect(resolve[:schema]["digest"]).not_to eq(first)
    end
  end

  describe "failures" do
    it "rejects a table outside the allowlist" do
      result = resolve(target_table: "orders")

      expect(result[:success]).to be(false)
      expect(result[:errors].first).to match(/not importable/)
    end

    it "rejects a blank table" do
      result = resolve(target_table: "")

      expect(result[:success]).to be(false)
      expect(result[:errors].first).to match(/not importable/)
    end

    it "requires a category" do
      result = resolve(category: nil)

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("category is required")
    end

    it "rejects a category from another company" do
      other_company = create(:company)
      other_category = product_import_category(company: other_company)

      result = resolve(category: other_category)

      expect(result[:success]).to be(false)
      expect(result[:errors].first).to match(/does not belong/)
    end

    it "rejects a category for another resource" do
      other_category = Seed::CategoryService.create(
        company: company, name: "Customers #{SecureRandom.hex(3)}", resource_name: "customers"
      )

      result = resolve(category: other_category)

      expect(result[:success]).to be(false)
      expect(result[:errors].first).to match(/is not for 'products'/)
    end

    it "rejects a property display name that collides with a model column" do
      collision = Seed::CategoryService.create(
        company: company,
        name: "Collision #{SecureRandom.hex(3)}",
        resource_name: "products",
        properties: { property_string_1: "name" }
      )

      result = resolve(category: collision)

      expect(result[:success]).to be(false)
      expect(result[:errors].first).to match(/defined more than once/)
    end
  end

  it "keeps the FE picker map in sync with IMPORTABLE_RESOURCES" do
    source = Rails.root.join("app/javascript/controllers/helpers/import_tables.js").read
    keys = source.scan(/^\s{2}([a-z_]+):\s*"/).flatten

    expect(keys).to match_array(IMPORTABLE_RESOURCES.keys)
  end
end
