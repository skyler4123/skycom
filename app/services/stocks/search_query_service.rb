# frozen_string_literal: true

# app/services/stocks/search_query_service.rb

# TableConfig-driven dynamic search/filter for the Stocks index.
# All logic lives in DynamicSearch::BaseQueryService. Contract: shared example
# "dynamic search query service" (spec/support/shared_examples/dynamic_search_service.rb).
class Stocks::SearchQueryService < DynamicSearch::BaseQueryService
  def self.model = Stock
  def self.fallback_resource_name = "stocks"
end
