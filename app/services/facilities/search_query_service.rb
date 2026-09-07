# frozen_string_literal: true

# app/services/facilities/search_query_service.rb

# TableConfig-driven dynamic search/filter for the Facilities index.
# All logic lives in DynamicSearch::BaseQueryService. Contract: shared example
# "dynamic search query service" (spec/support/shared_examples/dynamic_search_service.rb).
class Facilities::SearchQueryService < DynamicSearch::BaseQueryService
  def self.model = Facility
  def self.fallback_resource_name = "facilities"
end
