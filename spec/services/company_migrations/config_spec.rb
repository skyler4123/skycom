# frozen_string_literal: true

require "rails_helper"
require "csv"

RSpec.describe CompanyMigrations::Config do
  def customers_config
    {
      "version" => 1,
      "source" => { "has_header" => true },
      "targets" => [
        {
          "resource" => "customers",
          "identity" => { "column" => "Customer Id" },
          "category" => {
            "mode" => "create_or_reuse",
            "name" => "Imported Customers",
            "properties" => { "property_string_1" => "Company", "property_string_2" => "City" },
            "visible_columns" => %w[name email property_string_1 property_string_2]
          },
          "columns" => {
            "First Name" => { "target" => "name" },
            "Email" => { "target" => "email" },
            "Phone 1" => { "target" => "phone_number" },
            "City" => { "target" => "property_string_2" },
            "Website" => { "target" => "metadata.website" }
          },
          "defaults" => { "country" => "us", "currency" => "usd", "lifecycle_status" => "active" }
        }
      ]
    }
  end

  describe "a correct customers config" do
    it "is valid and exposes source and string-keyed targets" do
      config = described_class.new(customers_config)

      expect(config).to be_valid
      expect(config.errors).to be_empty
      expect(config.source).to eq("has_header" => true)
      expect(config.targets.size).to eq(1)
      expect(config.targets.first["resource"]).to eq("customers")
    end

    it "maps only columns that exist in the fixture header" do
      header = CSV.read(Rails.root.join("faker/files/customers-10.csv"), headers: true).headers

      mapped = described_class.new(customers_config).targets.flat_map { |target| target["columns"].keys }

      expect(mapped - header).to be_empty
    end

    it "accepts a lookup resolved by external_id" do
      raw = customers_config
      raw["targets"][0]["columns"]["Index"] = {
        "target" => "branch_id",
        "lookup" => { "resource" => "branches", "by" => "external_id" }
      }

      config = described_class.new(raw)

      expect(config).to be_valid
    end

    it "rejects a non-1 version" do
      raw = customers_config
      raw["version"] = 2

      config = described_class.new(raw)

      expect(config).not_to be_valid
      expect(config.errors.join).to match(/version/)
    end

    it "rejects empty targets" do
      raw = customers_config
      raw["targets"] = []

      config = described_class.new(raw)

      expect(config).not_to be_valid
      expect(config.errors.join).to match(/target/i)
    end

    it "rejects a missing identity" do
      raw = customers_config
      raw["targets"][0]["identity"] = {}

      config = described_class.new(raw)

      expect(config).not_to be_valid
      expect(config.errors.join).to match(/identity/)
    end

    it "rejects an excluded resource" do
      raw = customers_config
      raw["targets"][0]["resource"] = "roles"

      config = described_class.new(raw)

      expect(config).not_to be_valid
      expect(config.errors.join).to match(/not importable/)
    end

    it "rejects an unknown model" do
      raw = customers_config
      raw["targets"][0]["resource"] = "unicorns"

      config = described_class.new(raw)

      expect(config).not_to be_valid
      expect(config.errors.join).to match(/unknown model/)
    end

    it "rejects a forbidden target column" do
      raw = customers_config
      raw["targets"][0]["columns"]["Sneaky"] = { "target" => "id" }

      config = described_class.new(raw)

      expect(config).not_to be_valid
      expect(config.errors.join).to match(/cannot be imported/)
    end

    it "rejects a forbidden default target" do
      raw = customers_config
      raw["targets"][0]["defaults"]["id"] = "abc"

      config = described_class.new(raw)

      expect(config).not_to be_valid
      expect(config.errors.join).to match(/cannot be imported/)
    end

    it "rejects a lookup whose by is not external_id" do
      raw = customers_config
      raw["targets"][0]["columns"]["Index"] = {
        "target" => "branch_id",
        "lookup" => { "resource" => "branches", "by" => "code" }
      }

      config = described_class.new(raw)

      expect(config).not_to be_valid
      expect(config.errors.join).to match(/lookup/)
    end

    it "rejects a reuse category without category_id" do
      raw = customers_config
      raw["targets"][0]["category"] = { "mode" => "reuse" }

      config = described_class.new(raw)

      expect(config).not_to be_valid
      expect(config.errors.join).to match(/category_id/)
    end

    it "rejects columns that are not an object" do
      raw = customers_config
      raw["targets"][0]["columns"] = []

      config = described_class.new(raw)

      expect(config).not_to be_valid
      expect(config.errors.join).to match(/columns/)
    end
  end

  describe "#digest" do
    it "is stable across key order" do
      reordered = {
        "targets" => customers_config["targets"],
        "source" => { "has_header" => true },
        "version" => 1
      }

      expect(described_class.new(customers_config).digest).to eq(described_class.new(reordered).digest)
    end
  end
end
