# frozen_string_literal: true

require "rails_helper"

RSpec.describe Imports::SampleService do
  let!(:company) { create(:company) }
  let(:category) { product_import_category(company: company) }
  let(:resolved) { Imports::SchemaResolver.call(company: company, target_table: "products", category: category) }

  def sample
    described_class.call(
      company: company,
      schema: resolved[:schema],
      model: resolved[:model],
      category: category
    )
  end

  it "renders records under the resolved friendly headers" do
    create_product_in_category(company: company, category: category, name: "Sample Serum")
    other_category = product_import_category(company: company)
    create_product_in_category(company: company, category: other_category, name: "Other Category Product")

    result = sample
    labels = result["headers"].map { |entry| entry["header"] }

    expect(labels).to include("name", "business_type", "Skin Type Suitability", "Volume (ml)")
    expect(labels).not_to include("property_string_1")
    expect(result["rows"].map { |row| row["name"] }).to include("Sample Serum")
    expect(result["rows"].map { |row| row["name"] }).not_to include("Other Category Product")
    expect(result["total_records"]).to eq(1)
  end

  it "shows enum columns as labels, not integers" do
    create_product_in_category(company: company, category: category)

    value = sample["rows"].first["business_type"]

    expect(value).to be_a(String)
    expect(Product.business_types.keys).to include(value)
  end

  it "limits to IMPORT_PREVIEW_ROW_LIMIT records" do
    (IMPORT_PREVIEW_ROW_LIMIT + 2).times { create_product_in_category(company: company, category: category) }

    result = sample

    expect(result["rows"].size).to eq(IMPORT_PREVIEW_ROW_LIMIT)
    expect(result["total_records"]).to eq(IMPORT_PREVIEW_ROW_LIMIT + 2)
  end

  it "returns headers with no rows for an empty category" do
    result = sample

    expect(result["rows"]).to be_empty
    expect(result["headers"]).to be_present
    expect(result["total_records"]).to eq(0)
  end
end
