# frozen_string_literal: true

# app/services/brands/search_query_service.rb

# TableConfig-driven dynamic search/filter for the Brands index.
# All logic lives in DynamicSearch::BaseQueryService. Contract: shared example
# "dynamic search query service" (spec/support/shared_examples/dynamic_search_service.rb).
class Brands::SearchQueryService < DynamicSearch::BaseQueryService
  def self.model = Brand
  def self.fallback_resource_name = "brands"
end
