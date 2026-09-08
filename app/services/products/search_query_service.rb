# frozen_string_literal: true

# app/services/products/search_query_service.rb

# TableConfig-driven dynamic search/filter for the Products index.
# All logic lives in DynamicSearch::BaseQueryService — this class only declares the model
# and the fallback TableConfig resource_name. Spec contract: shared example
# "dynamic search query service" (spec/support/shared_examples/dynamic_search_service.rb).
class Products::SearchQueryService < DynamicSearch::BaseQueryService
  def self.model = Product
  def self.fallback_resource_name = "products"
end
