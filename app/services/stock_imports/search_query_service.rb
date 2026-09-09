# frozen_string_literal: true

# app/services/stock_imports/search_query_service.rb

# TableConfig-driven dynamic search/filter for the StockImports index.
# All logic lives in DynamicSearch::BaseQueryService. Contract: shared example
# "dynamic search query service" (spec/support/shared_examples/dynamic_search_service.rb).
class StockImports::SearchQueryService < DynamicSearch::BaseQueryService
  def self.model = StockImport
  def self.fallback_resource_name = "stock_imports"
end
