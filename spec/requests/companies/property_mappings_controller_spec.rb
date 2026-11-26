# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::PropertyMappingsController computed columns", type: :request do
  let(:company) { create(:company) }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "products") }
  let(:property_mapping) { category.default_property_mapping }

  before do
    get sign_in_for_test_path(email: company.user.email)
  end

  it "returns the computed catalog for a product mapping" do
    get "/companies/#{company.id}/property_mappings/#{property_mapping.id}.json"

    body = JSON.parse(response.body)["property_mapping"]
    expect(body["computed_columns"]).to include(
      "key" => "quantity", "name" => "Quantity", "type" => "integer"
    )
  end

  it "returns an empty computed catalog for a resource without computed columns" do
    stock_category = Seed::CategoryService.find_or_create_for(company: company, resource_name: "stocks")
    stock_mapping = stock_category.default_property_mapping

    get "/companies/#{company.id}/property_mappings/#{stock_mapping.id}.json"

    body = JSON.parse(response.body)["property_mapping"]
    expect(body["computed_columns"]).to eq([])
  end
end
