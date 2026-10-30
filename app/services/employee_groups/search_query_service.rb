# frozen_string_literal: true

# app/services/employee_groups/search_query_service.rb

# TableConfig-driven dynamic search/filter for the Employee Groups index.
# All logic lives in DynamicSearch::BaseQueryService. Contract: shared example
# "dynamic search query service" (spec/support/shared_examples/dynamic_search_service.rb).
class EmployeeGroups::SearchQueryService < DynamicSearch::BaseQueryService
  def self.model = EmployeeGroup
  def self.fallback_resource_name = "employee_groups"
end
