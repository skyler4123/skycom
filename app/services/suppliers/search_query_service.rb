# frozen_string_literal: true

# app/services/suppliers/search_query_service.rb

# TableConfig-driven dynamic search/filter for the Suppliers index.
# All logic lives in DynamicSearch::BaseQueryService. Contract: shared example
# "dynamic search query service" (spec/support/shared_examples/dynamic_search_service.rb).
class Suppliers::SearchQueryService < DynamicSearch::BaseQueryService
  def self.model = Supplier
  def self.fallback_resource_name = "suppliers"
end
