# frozen_string_literal: true

require "rails_helper"

RSpec.describe Products::SearchQueryService do
  let(:company) { create(:company) }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "products") }
  let!(:table_config) do
    category.default_property_mapping.table_configs.destroy_all
    TableConfig.create!(company: company, category: category,
      property_mapping: category.default_property_mapping, resource_name: "products",
      metadata: { "columns" => [
        { "key" => "name", "name" => "Name", "visible" => true, "search" => true },
        { "key" => "property_string_1", "name" => "Color", "visible" => true },
        { "key" => "property_integer_1", "name" => "Qty", "visible" => true,
          "filter" => { "type" => "range", "buckets" => [ [ nil, 100 ], [ 100, nil ] ] } },
        { "key" => "property_boolean_1", "name" => "Active", "visible" => true,
          "filter" => { "type" => "boolean", "true_false" => true, "yes_no" => false } },
        { "key" => "property_datetime_1", "name" => "Released", "visible" => true,
          "filter" => { "type" => "date", "buckets" => [ [ 2024, 2025 ] ] } }
      ] })
  end

  def service(extra_params = {})
    described_class.new(company: company, params: ActionController::Parameters.new(
      { category_id: category.id }.merge(extra_params)
    ))
  end

  describe "#active?" do
    it "is false with no q/filters" do
      expect(service.active?).to be false
    end

    it "is false when q is present but the resolved config has no searchable column" do
      config2 = create(:company)
      s = described_class.new(company: config2, params: ActionController::Parameters.new(q: "red", filters: {}))
      expect(s.active?).to be false
    end

    it "is true with q when search is configured" do
      expect(service(q: "red").active?).to be true
    end

    it "is true with a whitelisted filter" do
      expect(service(filters: { "property_integer_1" => ":100" }).active?).to be true
    end

    it "is false with an unknown filter key" do
      expect(service(filters: { "property_string_1" => "x" }).active?).to be false
    end

    it "is false with a filter key present in config but without filter setting" do
      expect(service(filters: { "property_string_1" => "x" }).active?).to be false
    end

    it "is false with a blank filter value" do
      expect(service(filters: { "property_integer_1" => "" }).active?).to be false
    end

    it "is false when q is blank and no filters" do
      expect(service(q: "   ").active?).to be false
    end
  end

  describe "#search_options / #filter_string" do
    it "always scopes to company + category" do
      expect(service(q: "red").search_options[:filter])
        .to eq(%(company_id = "#{company.id}" AND category_id = "#{category.id}"))
    end

    it "adds branch scope when present" do
      branch = create(:branch, company: company)
      s = described_class.new(company: company, params: ActionController::Parameters.new(branch_id: branch.id, q: "red"))
      expect(s.search_options[:filter]).to include(%(branch_id = "#{branch.id}"))
    end

    it "passes configured search columns via attributes_to_search_on" do
      expect(service(q: "red").search_options[:attributes_to_search_on]).to eq([ "name" ])
    end

    it "omits attributes_to_search_on for filter-only queries" do
      expect(service(filters: { "property_boolean_1" => "true" }).search_options).not_to have_key(:attributes_to_search_on)
    end

    it "caps hits per page" do
      expect(service(q: "red").search_options[:hits_per_page]).to eq(Products::SearchQueryService::MS_SEARCH_MAX_IDS)
    end

    it "builds range expressions from min:max" do
      expect(service(filters: { "property_integer_1" => ":100" }).filter_string).to include("property_integer_1 < 100")
      expect(service(filters: { "property_integer_1" => "100:500" }).filter_string).to include("property_integer_1 >= 100 AND property_integer_1 < 500")
      expect(service(filters: { "property_integer_1" => "500:" }).filter_string).to include("property_integer_1 >= 500")
    end

    it "supports decimal bounds" do
      expect(service(filters: { "property_integer_1" => ":10.5" }).filter_string).to include("property_integer_1 < 10.5")
    end

    it "builds half-open year bounds for date filters" do
      expect(service(filters: { "property_datetime_1" => "2024:2025" }).filter_string)
        .to include("property_datetime_1 >= 2024-01-01T00:00:00Z AND property_datetime_1 < 2025-01-01T00:00:00Z")
    end

    it "accepts boolean values" do
      expect(service(filters: { "property_boolean_1" => "true" }).filter_string).to include("property_boolean_1 = true")
      expect(service(filters: { "property_boolean_1" => "false" }).filter_string).to include("property_boolean_1 = false")
    end

    it "ignores hostile or malformed values" do
      expect(service(filters: { "property_boolean_1" => %(1" OR 1=1 --) }).filter_string).not_to include("OR")
      expect(service(filters: { "property_boolean_1" => %(1" OR 1=1 --) }).active?).to be false
      expect(service(filters: { "property_integer_1" => "abc:xyz" }).filter_string).not_to include("abc")
      expect(service(filters: { "property_integer_1" => "abc:xyz" }).active?).to be false
      expect(service(filters: { "property_datetime_1" => "20x4:2025" }).filter_string).not_to include("20x4")
      expect(service(filters: { "property_integer_1" => "nonsense" }).filter_string).not_to include("nonsense")
    end

    it "accepts plain Hash params (JSON API style)" do
      s = described_class.new(company: company, params: { "q" => "red", "category_id" => category.id }.with_indifferent_access)
      expect(s.active?).to be true
    end
  end

  describe "#record_ids" do
    before(:all) do
      @meili_available = begin
        Meilisearch::Rails.client.health["status"] == "available"
      rescue StandardError
        false
      end
      unless @meili_available
        raise "Meilisearch not reachable at #{Meilisearch::Rails.configuration[:meilisearch_url]}. Run `docker compose up -d meilisearch`."
      end
    end

    before { Product.ms_clear_index! }
    after { Product.ms_clear_index! }

    it "returns nil when not active" do
      expect(service.record_ids).to be_nil
    end

    it "returns ids matching the keyword, tenant-scoped, honoring configured search columns" do
      other = create(:company)
      red  = create(:product, company: company, name: "Crimson Banner", category: category, property_integer_1: 50)
      blue = create(:product, company: company, name: "Azure Banner", category: category, property_integer_1: 250)
      noise = create(:product, company: other, name: "Crimson Other")
      [ red, blue, noise ].each { |p| p.ms_index!(true) }

      expect(service(q: "Crimson").record_ids).to contain_exactly(red.id)
    end

    it "restricts search to configured columns (name only here — Color is not search-enabled)" do
      p1 = create(:product, company: company, name: "Plain Widget", category: category, property_string_1: "Turquoise")
      p1.ms_index!(true)
      expect(service(q: "Turquoise").record_ids).to eq([])
    end

    it "applies range filters" do
      small = create(:product, company: company, name: "Small Thing", category: category, property_integer_1: 50)
      large = create(:product, company: company, name: "Large Thing", category: category, property_integer_1: 250)
      [ small, large ].each { |p| p.ms_index!(true) }

      expect(service(filters: { "property_integer_1" => ":100" }).record_ids).to contain_exactly(small.id)
      expect(service(filters: { "property_integer_1" => "100:" }).record_ids).to contain_exactly(large.id)
    end

    it "combines q + filter with AND" do
      small = create(:product, company: company, name: "Crimson Small", category: category, property_integer_1: 50)
      large = create(:product, company: company, name: "Crimson Large", category: category, property_integer_1: 250)
      [ small, large ].each { |p| p.ms_index!(true) }

      s = service(q: "Crimson", filters: { "property_integer_1" => ":100" })
      expect(s.record_ids).to contain_exactly(small.id)
    end
  end
end
