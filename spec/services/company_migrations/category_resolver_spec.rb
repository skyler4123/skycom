# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyMigrations::CategoryResolver do
  let!(:company) { create(:company) }

  describe "reuse" do
    it "reuses a category by id" do
      category = Category.create!(company: company, name: "VIP Customers", resource_name: "customers")

      result = described_class.call(
        company: company,
        resource: "customers",
        category_config: { "mode" => "reuse", "category_id" => category.id }
      )

      expect(result[:success]).to be(true)
      expect(result[:category]).to eq(category)
      expect(result[:errors]).to be_empty
    end

    it "returns errors for an unknown category_id" do
      result = described_class.call(
        company: company,
        resource: "customers",
        category_config: { "mode" => "reuse", "category_id" => SecureRandom.uuid }
      )

      expect(result[:success]).to be(false)
      expect(result[:category]).to be_nil
      expect(result[:errors]).to be_present
    end
  end

  describe "create_or_reuse" do
    it "creates the category, property mapping and table config" do
      result = described_class.call(
        company: company,
        resource: "customers",
        category_config: {
          "mode" => "create_or_reuse",
          "name" => "Imported Customers",
          "properties" => { "property_string_1" => "Company", "property_integer_1" => "Loyalty points" },
          "visible_columns" => %w[name email property_string_1]
        }
      )

      expect(result[:success]).to be(true)
      expect(result[:errors]).to be_empty

      category = result[:category]
      expect(category.name).to eq("Imported Customers")
      expect(category.resource_name).to eq("customers")

      properties = category.default_property_mapping.properties
      expect(properties.map { |property| property["key"] }).to contain_exactly("property_string_1", "property_integer_1")
      expect(properties.find { |property| property["key"] == "property_string_1" }["name"]).to eq("Company")

      table_config = category.default_property_mapping.table_configs.first
      expect(table_config).to be_present
      expect(table_config.columns.map { |column| column["key"] }).to include("name", "email", "property_string_1")
    end

    it "reuses an existing category with the same name and resource" do
      config = { "mode" => "create_or_reuse", "name" => "Imported Customers" }

      first = described_class.call(company: company, resource: "customers", category_config: config)
      second = described_class.call(company: company, resource: "customers", category_config: config)

      expect(second[:category]).to eq(first[:category])
      expect(company.categories.where(name: "Imported Customers", resource_name: "customers").count).to eq(1)
    end
  end
end
