# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::TableConfigsController", type: :request do
  let(:company) { create(:company) }
  let(:owner_user) { company.user }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "products") }
  let!(:config) do
    category.default_property_mapping.table_configs.destroy_all
    TableConfig.create!(company: company, category: category,
      property_mapping: category.default_property_mapping, resource_name: "products",
      metadata: { "columns" => [
        { "key" => "property_string_1", "name" => "Color", "visible" => true }
      ] }
    )
  end

  before do
    get sign_in_for_test_path(email: owner_user.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  def patch_columns(columns)
    patch "/companies/#{company.id}/table_configs/#{config.id}", params: {
      table_config: { metadata: { columns: columns } }
    }
  end

  describe "PATCH #update with search/filter column settings" do
    it "coerces search and normalizes typed filter buckets" do
      patch_columns({ "0" => { "key" => "property_string_1", "name" => "Color", "visible" => "true",
                               "search" => "true", "filter" => "" },
                      "1" => { "key" => "property_integer_1", "name" => "Qty", "visible" => "true",
                               "search" => "false",
                               "filter" => { "type" => "range", "active" => "true",
                                 "buckets" => { "0" => { "from" => "", "to" => "100" },
                                                "1" => { "from" => "100", "to" => "" } } } } })

      cols = config.reload.columns
      expect(cols[0]).to include("search" => true)
      expect(cols[0]).not_to have_key("filter")
      expect(cols[1]).to include("search" => false,
        "filter" => { "type" => "range", "buckets" => [ [ nil, 100 ], [ 100, nil ] ], "active" => true })
    end

    it "stores the filter with active: false when the Active checkbox is off" do
      patch_columns({ "0" => { "key" => "property_integer_1", "name" => "Qty", "visible" => "true",
                               "filter" => { "type" => "range", "active" => "false",
                                 "buckets" => { "0" => { "from" => "0", "to" => "50" } } } } })

      expect(config.reload.columns[0]["filter"]).to eq(
        "type" => "range", "buckets" => [ [ 0, 50 ] ], "active" => false
      )
    end

    it "drops the filter when the Filter Type is blank" do
      patch_columns({ "0" => { "key" => "property_integer_1", "name" => "Qty", "visible" => "true",
                               "filter" => { "type" => "", "active" => "true",
                                 "buckets" => { "0" => { "from" => "0", "to" => "50" } } } } })

      expect(config.reload.columns[0]).not_to have_key("filter")
    end

    it "keeps decimal bucket values as floats" do
      patch_columns({ "0" => { "key" => "property_decimal_1", "name" => "Price", "visible" => "true",
                               "filter" => { "type" => "range", "active" => "true",
                                 "buckets" => { "0" => { "from" => "1.5", "to" => "10.25" } } } } })

      expect(config.reload.columns[0]["filter"]["buckets"]).to eq([ [ 1.5, 10.25 ] ])
    end

    it "keeps date bucket values as integers" do
      patch_columns({ "0" => { "key" => "property_datetime_1", "name" => "Released", "visible" => "true",
                               "filter" => { "type" => "date", "active" => "true",
                                 "buckets" => { "0" => { "from" => "2024", "to" => "2025" } } } } })

      expect(config.reload.columns[0]["filter"]["buckets"]).to eq([ [ 2024, 2025 ] ])
    end

    it "drops fully blank buckets and rejects a filter with no usable buckets" do
      expect {
        patch_columns({ "0" => { "key" => "property_integer_1", "name" => "Qty", "visible" => "true",
                                 "filter" => { "type" => "range", "active" => "true",
                                   "buckets" => { "0" => { "from" => "", "to" => "" } } } } })
      }.not_to change { config.reload.columns }
      expect(response).to redirect_to(edit_company_table_config_path(company, config))
    end

    it "rejects a bucket whose from value is not below its to value" do
      expect {
        patch_columns({ "0" => { "key" => "property_integer_1", "name" => "Qty", "visible" => "true",
                                 "filter" => { "type" => "range", "active" => "true",
                                   "buckets" => { "0" => { "from" => "500", "to" => "100" } } } } })
      }.not_to change { config.reload.columns }
      expect(response).to redirect_to(edit_company_table_config_path(company, config))
    end
  end

  describe "PATCH #update with canonical column names" do
    it "stores an empty columns array when columns_submitted is 1 and no columns are sent" do
      patch "/companies/#{company.id}/table_configs/#{config.id}", params: {
        table_config: { metadata: { columns_submitted: "1" } }
      }

      expect(config.reload.columns).to eq([])
    end

    it "normalizes a submitted standard name to the fixed label" do
      patch_columns({ "0" => { "key" => "name", "name" => "Product Title", "visible" => "true" } })

      expect(config.reload.columns.first["name"]).to eq("Name")
    end

    it "normalizes property and extra names from Property Mapping" do
      config.property_mapping.update!(metadata: {
        "properties" => [
          { "key" => "property_string_1", "name" => "Color", "type" => "string" }
        ],
        "extra_columns" => [
          { "key" => "extra_1", "name" => "Extra Demo", "type" => "string" }
        ]
      })

      patch_columns({
        "0" => { "key" => "property_string_1", "name" => "Old Color", "visible" => "true" },
        "1" => { "key" => "extra_1", "name" => "Old Extra", "visible" => "true" }
      })

      expect(config.reload.columns.map { |column| column["name"] }).to eq([ "Color", "Extra Demo" ])
    end
  end
end
