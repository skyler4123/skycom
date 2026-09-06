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
    it "coerces search to boolean and JSON-parses the filter textarea value" do
      patch_columns({ "0" => { "key" => "property_string_1", "name" => "Color", "visible" => "true",
                               "search" => "true", "filter" => "" },
                      "1" => { "key" => "property_integer_1", "name" => "Qty", "visible" => "true",
                               "search" => "false",
                               "filter" => '{"type":"range","buckets":[[null,100],[100,null]]}' } })

      cols = config.reload.columns
      expect(cols[0]).to include("search" => true)
      expect(cols[0]).not_to have_key("filter")
      expect(cols[1]).to include("search" => false,
        "filter" => { "type" => "range", "buckets" => [ [ nil, 100 ], [ 100, nil ] ] })
    end

    it "rejects invalid filter JSON with a redirect back to the edit page" do
      expect {
        patch_columns({ "0" => { "key" => "property_string_1", "name" => "Color", "visible" => "true",
                                 "filter" => "{invalid json" } })
      }.not_to change { config.reload.columns }
      expect(response).to redirect_to(edit_company_table_config_path(company, config))
    end

    it "rejects filter config invalid per schema without saving" do
      patch_columns({ "0" => { "key" => "property_string_1", "name" => "Color", "visible" => "true",
                               "filter" => '{"type":"range","buckets":[[null,null]]}' } })
      expect(response).to redirect_to(edit_company_table_config_path(company, config))
      expect(config.reload.columns.first).not_to have_key("filter")
    end
  end
end
