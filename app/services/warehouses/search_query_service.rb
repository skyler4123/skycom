# frozen_string_literal: true

# app/services/warehouses/search_query_service.rb

# TableConfig-driven dynamic search/filter for the Warehouses index.
# All logic lives in DynamicSearch::BaseQueryService. Contract: shared example
# "dynamic search query service" (spec/support/shared_examples/dynamic_search_service.rb).
class Warehouses::SearchQueryService < DynamicSearch::BaseQueryService
  def self.model = Warehouse
  def self.fallback_resource_name = "warehouses"
end
