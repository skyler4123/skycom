# frozen_string_literal: true

# app/services/branches/search_query_service.rb

# TableConfig-driven dynamic search/filter for the Branches index.
# All logic lives in DynamicSearch::BaseQueryService. Contract: shared example
# "dynamic search query service" (spec/support/shared_examples/dynamic_search_service.rb).
class Branches::SearchQueryService < DynamicSearch::BaseQueryService
  def self.model = Branch
  def self.fallback_resource_name = "branches"
end
