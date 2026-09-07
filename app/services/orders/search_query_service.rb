# frozen_string_literal: true

# app/services/orders/search_query_service.rb

# TableConfig-driven dynamic search/filter for the Orders index.
# All logic lives in DynamicSearch::BaseQueryService. Contract: shared example
# "dynamic search query service" (spec/support/shared_examples/dynamic_search_service.rb).
class Orders::SearchQueryService < DynamicSearch::BaseQueryService
  def self.model = Order
  def self.fallback_resource_name = "orders"
end
