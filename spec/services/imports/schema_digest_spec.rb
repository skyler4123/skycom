# frozen_string_literal: true

require "rails_helper"

RSpec.describe Imports::SchemaDigest do
  it "ignores key order" do
    first = {
      "target_table" => "products",
      "category_id" => "category-1",
      "headers" => [ { "header" => "name", "required" => true } ]
    }
    second = {
      "headers" => [ { "required" => true, "header" => "name" } ],
      "category_id" => "category-1",
      "target_table" => "products"
    }

    expect(described_class.call(first)).to eq(described_class.call(second))
  end

  it "changes when a header changes" do
    schema = {
      "target_table" => "products",
      "category_id" => "category-1",
      "headers" => [ { "header" => "name", "required" => true } ]
    }
    changed = schema.deep_dup
    changed["headers"][0]["required"] = false

    expect(described_class.call(schema)).not_to eq(described_class.call(changed))
  end

  it "ignores extra keys outside the digest contract" do
    schema = {
      "target_table" => "products",
      "category_id" => "category-1",
      "headers" => [ { "header" => "name" } ]
    }

    expect(described_class.call(schema)).to eq(described_class.call(schema.merge("model" => "Product")))
  end
end
