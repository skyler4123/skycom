# frozen_string_literal: true

# spec/support/shared_examples/dynamic_search_index_controller.rb
#
# Request-level contract for controller indexes wired to a DynamicSearch::BaseQueryService
# subclass. Host specs provide five lets:
#   resource_name    — Category/TableConfig resource_name, e.g. "branches"
#   index_class      — the AR class, e.g. Branch
#   json_key         — the index JSON list key, e.g. "branches"
#   base_json_path   — lambda-free string using `company`, e.g. "/companies/#{company.id}/branches.json"
#   record           — lambda: .call(company:, category:, **attrs) creating one record
# Optional: hidden_record — a keyword-matching record the controller's pre-search scope
#   must exclude (e.g. a discarded employee); enables the scope-intersection example.

RSpec.shared_examples "dynamic search index controller" do
  let(:company) { create(:company) }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: resource_name) }
  let(:hidden_record) { nil }
  let!(:table_config) do
    category.default_property_mapping.table_configs.destroy_all
    TableConfig.create!(company: company, category: category,
      property_mapping: category.default_property_mapping, resource_name: resource_name,
      metadata: { "columns" => [
        { "key" => "name", "name" => "Name", "visible" => true, "search" => true },
        { "key" => "property_integer_1", "name" => "Qty", "visible" => true,
          "filter" => { "type" => "range", "active" => true, "buckets" => [ [ nil, 100 ], [ 100, nil ] ] } }
      ] })
  end

  before do
    get sign_in_for_test_path(email: company.user.email)
  end

  def index_url(extra = {})
    "#{base_json_path}?#{ { category_id: category.id }.merge(extra).to_query }"
  end

  describe "DB path (no search params)" do
    let!(:plain) { record.call(company: company, category: category, name: "NoIndex Plain") }

    it "returns records without touching Meilisearch" do
      allow(index_class).to receive(:ms_raw_search).and_raise("should not be called")
      get index_url

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)[json_key].map { |r| r["id"] }).to include(plain.id)
    end
  end

  describe "Meilisearch path" do
    let(:small) { record.call(company: company, category: category, name: "Crimson Small", property_integer_1: 50) }
    let(:large) { record.call(company: company, category: category, name: "Crimson Large", property_integer_1: 250) }

    before do
      raise "Meilisearch not reachable. Run `docker compose up -d meilisearch`." unless
        begin
          Meilisearch::Rails.client.health["status"] == "available"
        rescue StandardError
          false
        end
      index_class.ms_clear_index!
    end

    after { index_class.ms_clear_index! }

    it "filters by keyword and excludes other companies" do
      other = create(:company)
      other_category = Seed::CategoryService.find_or_create_for(company: other, resource_name: resource_name)
      noise = record.call(company: other, category: other_category, name: "Crimson Noise")
      [ small, large, noise ].each { |r| r.ms_index!(true) }

      get index_url(q: "Crimson")
      ids = JSON.parse(response.body)[json_key].map { |r| r["id"] }
      expect(ids).to contain_exactly(small.id, large.id)
    end

    it "restricts results to a configured range filter" do
      [ small, large ].each { |r| r.ms_index!(true) }

      get index_url("filters" => { "property_integer_1" => ":100" })
      ids = JSON.parse(response.body)[json_key].map { |r| r["id"] }
      expect(ids).to contain_exactly(small.id)
    end

    it "returns 503 with errors when Meilisearch fails" do
      allow(index_class).to receive(:ms_raw_search).and_raise(Meilisearch::CommunicationError, "down")

      get index_url(q: "Crimson")

      expect(response).to have_http_status(:service_unavailable)
      expect(JSON.parse(response.body)["errors"]).to include("Search is temporarily unavailable. Please try again.")
    end

    it "intersects search ids with pre-existing scope filters" do
      skip "host spec provides no hidden_record" if hidden_record.nil?
      [ small, large, hidden_record ].each { |r| r.ms_index!(true) }

      get index_url(q: "Crimson")
      ids = JSON.parse(response.body)[json_key].map { |r| r["id"] }
      expect(ids).to include(small.id, large.id)
      expect(ids).not_to include(hidden_record.id)
    end
  end
end
