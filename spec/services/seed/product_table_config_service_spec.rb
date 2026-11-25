# frozen_string_literal: true

require "rails_helper"

RSpec.describe Seed::ProductTableConfigService do
  let(:company) { create(:company) }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "products") }
  let!(:config) do
    TableConfig.create!(
      company: company,
      category: category,
      property_mapping: category.default_property_mapping,
      resource_name: "products",
      name: "Products Grid",
      metadata: { "columns" => [
        { "key" => "name", "name" => "Name", "visible" => true },
        { "key" => "code", "name" => "Code", "visible" => true },
        { "key" => "unit_of_measure", "name" => "Unit", "visible" => false },
        { "key" => "property_string_1", "name" => "Color", "visible" => true }
      ] }
    )
  end

  def column_keys
    config.reload.columns.map { |column| column["key"] }
  end

  it "inserts missing core columns in order after code and before existing properties" do
    described_class.ensure_columns!(company: company)

    expect(column_keys).to eq(
      %w[name code brand price_cents cost_cents stock_quantity unit_of_measure workflow_status property_string_1]
    )
  end

  it "is idempotent" do
    described_class.ensure_columns!(company: company)
    expect(column_keys).to include("brand", "price_cents", "cost_cents", "stock_quantity", "workflow_status")
    keys_after_first_run = column_keys

    described_class.ensure_columns!(company: company)

    expect(column_keys).to eq(keys_after_first_run)
  end

  it "preserves a hidden existing column and its order" do
    described_class.ensure_columns!(company: company)
    expect(column_keys).to include("brand", "price_cents")

    unit = config.reload.columns.find { |column| column["key"] == "unit_of_measure" }
    expect(unit).to include("visible" => false, "name" => "Unit")
  end

  it "leaves configs for other companies and other resources untouched" do
    other_company = create(:company)
    other_category = Seed::CategoryService.find_or_create_for(company: other_company, resource_name: "products")
    other_config = TableConfig.create!(
      company: other_company,
      category: other_category,
      property_mapping: other_category.default_property_mapping,
      resource_name: "products",
      name: "Other Products",
      metadata: { "columns" => [ { "key" => "name", "name" => "Name", "visible" => true } ] }
    )

    stocks_category = Seed::CategoryService.find_or_create_for(company: company, resource_name: "stocks")
    stocks_config = TableConfig.create!(
      company: company,
      category: stocks_category,
      property_mapping: stocks_category.default_property_mapping,
      resource_name: "stocks",
      name: "Stocks Grid",
      metadata: { "columns" => [ { "key" => "name", "name" => "Name", "visible" => true } ] }
    )

    described_class.ensure_columns!(company: company)

    expect(other_config.reload.columns.map { |column| column["key"] }).to eq(%w[name])
    expect(stocks_config.reload.columns.map { |column| column["key"] }).to eq(%w[name])
    expect(config.reload.columns.map { |column| column["key"] }).to include("brand", "price_cents")
  end
end
