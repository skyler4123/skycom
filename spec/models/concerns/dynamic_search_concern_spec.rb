require "rails_helper"

RSpec.describe "DynamicSearchConcern" do
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

  describe "connection to Meilisearch" do
    it "returns a healthy status" do
      expect(Meilisearch::Rails.client.health).to eq("status" => "available")
    end
  end

  describe "index settings" do
    it "applies searchable + filterable attributes for a dynamic model" do
      settings = Product.ms_index.settings
      expect(settings["searchableAttributes"]).to include("name", "description", "code", "property_string_1", "property_integer_1")
      expect(settings["filterableAttributes"]).to include("company_id", "property_integer_1", "property_boolean_1")
    end
  end
end