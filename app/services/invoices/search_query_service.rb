# frozen_string_literal: true

# app/services/invoices/search_query_service.rb

# TableConfig-driven dynamic search/filter for the Invoices index.
# All logic lives in DynamicSearch::BaseQueryService. Contract: shared example
# "dynamic search query service" (spec/support/shared_examples/dynamic_search_service.rb).
class Invoices::SearchQueryService < DynamicSearch::BaseQueryService
  def self.model = Invoice
  def self.fallback_resource_name = "invoices"
end
