# frozen_string_literal: true

# app/services/documents/search_query_service.rb

# TableConfig-driven dynamic search/filter for the Documents index.
# All logic lives in DynamicSearch::BaseQueryService. Contract: shared example
# "dynamic search query service" (spec/support/shared_examples/dynamic_search_service.rb).
class Documents::SearchQueryService < DynamicSearch::BaseQueryService
  def self.model = Document
  def self.fallback_resource_name = "documents"
end
