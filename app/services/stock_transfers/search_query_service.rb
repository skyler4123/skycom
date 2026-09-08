# frozen_string_literal: true

# app/services/stock_transfers/search_query_service.rb

# TableConfig-driven dynamic search/filter for the StockTransfers index.
# All logic lives in DynamicSearch::BaseQueryService. Contract: shared example
# "dynamic search query service" (spec/support/shared_examples/dynamic_search_service.rb).
class StockTransfers::SearchQueryService < DynamicSearch::BaseQueryService
  def self.model = StockTransfer
  def self.fallback_resource_name = "stock_transfers"
end
