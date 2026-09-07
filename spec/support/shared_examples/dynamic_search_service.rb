# frozen_string_literal: true

# spec/support/shared_examples/dynamic_search_service.rb
#
# Full behavioral contract for every DynamicSearch::BaseQueryService subclass
# (TableConfig-driven whitelist + filter-string building + Meilisearch integration).
# Host specs provide four lets:
#   service_class — the subclass under test
#   resource_name — Category/TableConfig resource_name, e.g. "products"
#   index_class   — the indexed AR class, e.g. Product
#   record        — lambda: .call(company:, category:, **column_attrs) creating one record

RSpec.shared_examples "dynamic search query service" do
  let(:company) { create(:company) }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: resource_name) }
  let!(:table_config) do
    category.default_property_mapping.table_configs.destroy_all
    TableConfig.create!(company: company, category: category,
      property_mapping: category.default_property_mapping, resource_name: resource_name,
      metadata: { "columns" => [
        { "key" => "name", "name" => "Name", "visible" => true, "search" => true },
        { "key" => "property_string_1", "name" => "Color", "visible" => true },
        { "key" => "property_integer_1", "name" => "Qty", "visible" => true,
          "filter" => { "type" => "range", "active" => true, "buckets" => [ [ nil, 100 ], [ 100, nil ] ] } },
        { "key" => "property_boolean_1", "name" => "Active", "visible" => true,
          "filter" => { "type" => "boolean", "active" => true, "true_false" => true, "yes_no" => false } },
        { "key" => "property_datetime_1", "name" => "Released", "visible" => true,
          "filter" => { "type" => "date", "active" => true, "buckets" => [ [ 2024, 2025 ] ] } }
      ] })
  end

  def service(extra_params = {})
    service_class.new(company: company, params: ActionController::Parameters.new(
      { category_id: category.id }.merge(extra_params)
    ))
  end

  describe "#active?" do
    it "is false with no q/filters" do
      expect(service.active?).to be false
    end

    it "is false when q is present but the resolved config has no searchable column" do
      other = create(:company)
      s = service_class.new(company: other, params: ActionController::Parameters.new(q: "red", filters: {}))
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

    it "ignores filters whose config is explicitly deactivated (active: false)" do
      cols = table_config.columns.map(&:deep_dup)
      cols.find { |c| c["key"] == "property_integer_1" }["filter"]["active"] = false
      table_config.update!(columns: cols)

      expect(service(filters: { "property_integer_1" => ":100" }).active?).to be false
    end

    it "treats a legacy filter config without active key as enabled" do
      cols = table_config.columns.map(&:deep_dup)
      cols.find { |c| c["key"] == "property_integer_1" }["filter"].delete("active")
      # update_columns bypasses validation — legacy rows predate the required key
      table_config.update_columns(metadata: { "columns" => cols })

      expect(service(filters: { "property_integer_1" => ":100" }).active?).to be true
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
      s = service_class.new(company: company, params: ActionController::Parameters.new(branch_id: branch.id, q: "red"))
      expect(s.search_options[:filter]).to include(%(branch_id = "#{branch.id}"))
    end

    it "passes configured search columns via attributes_to_search_on" do
      expect(service(q: "red").search_options[:attributes_to_search_on]).to eq([ "name" ])
    end

    it "omits attributes_to_search_on for filter-only queries" do
      expect(service(filters: { "property_boolean_1" => "true" }).search_options).not_to have_key(:attributes_to_search_on)
    end

    it "caps hits per page" do
      expect(service(q: "red").search_options[:hits_per_page]).to eq(service_class::MS_SEARCH_MAX_IDS)
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
      s = service_class.new(company: company, params: { "q" => "red", "category_id" => category.id }.with_indifferent_access)
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

    before { index_class.ms_clear_index! }
    after { index_class.ms_clear_index! }

    it "returns nil when not active" do
      expect(service.record_ids).to be_nil
    end

    it "returns ids matching the keyword, tenant-scoped" do
      other = create(:company)
      other_category = Seed::CategoryService.find_or_create_for(company: other, resource_name: resource_name)
      red  = record.call(company: company, category: category, name: "Crimson Banner", property_integer_1: 50)
      blue = record.call(company: company, category: category, name: "Azure Banner", property_integer_1: 250)
      noise = record.call(company: other, category: other_category, name: "Crimson Other")
      [ red, blue, noise ].each { |r| r.ms_index!(true) }

      expect(service(q: "Crimson").record_ids).to contain_exactly(red.id)
      expect(service(q: "Banner").record_ids).to contain_exactly(red.id, blue.id)
    end

    it "restricts search to configured columns (Color is not search-enabled)" do
      p1 = record.call(company: company, category: category, name: "Plain Widget", property_string_1: "Turquoise")
      p1.ms_index!(true)
      expect(service(q: "Turquoise").record_ids).to eq([])
    end

    it "applies range filters" do
      small = record.call(company: company, category: category, name: "Small Thing", property_integer_1: 50)
      large = record.call(company: company, category: category, name: "Large Thing", property_integer_1: 250)
      [ small, large ].each { |r| r.ms_index!(true) }

      expect(service(filters: { "property_integer_1" => ":100" }).record_ids).to contain_exactly(small.id)
      expect(service(filters: { "property_integer_1" => "100:" }).record_ids).to contain_exactly(large.id)
    end

    it "combines q + filter with AND" do
      small = record.call(company: company, category: category, name: "Crimson Small", property_integer_1: 50)
      large = record.call(company: company, category: category, name: "Crimson Large", property_integer_1: 250)
      [ small, large ].each { |r| r.ms_index!(true) }

      s = service(q: "Crimson", filters: { "property_integer_1" => ":100" })
      expect(s.record_ids).to contain_exactly(small.id)
    end
  end
end
