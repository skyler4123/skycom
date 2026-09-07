# frozen_string_literal: true

# app/services/services/search_query_service.rb

# TableConfig-driven dynamic search/filter for the Services index.
# All logic lives in DynamicSearch::BaseQueryService. Contract: shared example
# "dynamic search query service" (spec/support/shared_examples/dynamic_search_service.rb).
class Services::SearchQueryService < DynamicSearch::BaseQueryService
  def self.model = Service
  def self.fallback_resource_name = "services"
end
