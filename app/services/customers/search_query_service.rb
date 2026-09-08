# frozen_string_literal: true

# app/services/customers/search_query_service.rb

# TableConfig-driven dynamic search/filter for the Customers index.
# All logic lives in DynamicSearch::BaseQueryService. Contract: shared example
# "dynamic search query service" (spec/support/shared_examples/dynamic_search_service.rb).
class Customers::SearchQueryService < DynamicSearch::BaseQueryService
  def self.model = Customer
  def self.fallback_resource_name = "customers"
end
