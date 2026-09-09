# frozen_string_literal: true

# app/services/stock_exports/search_query_service.rb

# TableConfig-driven dynamic search/filter for the StockExports index.
# All logic lives in DynamicSearch::BaseQueryService. Contract: shared example
# "dynamic search query service" (spec/support/shared_examples/dynamic_search_service.rb).
class StockExports::SearchQueryService < DynamicSearch::BaseQueryService
  def self.model = StockExport
  def self.fallback_resource_name = "stock_exports"
end
