# frozen_string_literal: true

# app/services/events/search_query_service.rb

# TableConfig-driven dynamic search/filter for the Events index.
# All logic lives in DynamicSearch::BaseQueryService. Contract: shared example
# "dynamic search query service" (spec/support/shared_examples/dynamic_search_service.rb).
class Events::SearchQueryService < DynamicSearch::BaseQueryService
  def self.model = Event
  def self.fallback_resource_name = "events"
end
