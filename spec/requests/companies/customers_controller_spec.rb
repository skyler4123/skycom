# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::CustomersController search/filter", type: :request do
  let(:company) { create(:company) }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "customers") }
  let!(:table_config) do
    category.default_property_mapping.table_configs.destroy_all
    TableConfig.create!(company: company, category: category,
      property_mapping: category.default_property_mapping, resource_name: "customers",
      metadata: { "columns" => [
        { "key" => "name", "name" => "Name", "visible" => true, "search" => true },
        { "key" => "property_integer_1", "name" => "Visits", "visible" => true,
          "filter" => { "type" => "range", "buckets" => [ [ nil, 100 ], [ 100, nil ] ] } }
      ] })
  end

  before do
    get sign_in_for_test_path(email: company.user.email)
  end

  def index_url(params = {})
    "/companies/#{company.id}/customers.json?#{ { category_id: category.id }.merge(params).to_query }"
  end

  describe "DB path (no search params)" do
    let!(:customer) { create(:customer, company: company, category: category, name: "NoIndex Customer") }

    it "returns customers without touching Meilisearch" do
      allow(Customer).to receive(:ms_raw_search).and_raise("should not be called")
      get index_url

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["customers"].map { |c| c["id"] }).to include(customer.id)
    end
  end

  describe "Meilisearch path" do
    let(:small) { create(:customer, company: company, category: category, name: "Crimson Visitor", property_integer_1: 50) }
    let(:large) { create(:customer, company: company, category: category, name: "Crimson Regular", property_integer_1: 250) }

    before do
      raise "Meilisearch not reachable. Run `docker compose up -d meilisearch`." unless
        begin
          Meilisearch::Rails.client.health["status"] == "available"
        rescue StandardError
          false
        end
      Customer.ms_clear_index!
    end

    after { Customer.ms_clear_index! }

    it "filters by keyword and excludes other companies" do
      other = create(:company)
      other_category = Seed::CategoryService.find_or_create_for(company: other, resource_name: "customers")
      noise = create(:customer, company: other, category: other_category, name: "Crimson Noise")
      [ small, large, noise ].each { |c| c.ms_index!(true) }

      get index_url(q: "Crimson")
      ids = JSON.parse(response.body)["customers"].map { |c| c["id"] }
      expect(ids).to contain_exactly(small.id, large.id)
    end

    it "restricts results to a configured range filter" do
      [ small, large ].each { |c| c.ms_index!(true) }

      get index_url("filters" => { "property_integer_1" => ":100" })
      ids = JSON.parse(response.body)["customers"].map { |c| c["id"] }
      expect(ids).to contain_exactly(small.id)
    end

    it "returns 503 with errors when Meilisearch fails" do
      allow(Customer).to receive(:ms_raw_search).and_raise(Meilisearch::CommunicationError, "down")

      get index_url(q: "Crimson")

      expect(response).to have_http_status(:service_unavailable)
      expect(JSON.parse(response.body)["errors"]).to include("Search is temporarily unavailable. Please try again.")
    end
  end
end
