# frozen_string_literal: true

# app/services/departments/search_query_service.rb

# TableConfig-driven dynamic search/filter for the Departments index.
# All logic lives in DynamicSearch::BaseQueryService. Contract: shared example
# "dynamic search query service" (spec/support/shared_examples/dynamic_search_service.rb).
class Departments::SearchQueryService < DynamicSearch::BaseQueryService
  def self.model = Department
  def self.fallback_resource_name = "departments"
end
