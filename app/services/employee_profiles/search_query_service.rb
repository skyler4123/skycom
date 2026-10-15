# frozen_string_literal: true

# app/services/employee_profiles/search_query_service.rb

class EmployeeProfiles::SearchQueryService < DynamicSearch::BaseQueryService
  def self.model = EmployeeProfile
  def self.fallback_resource_name = "employee_profiles"
end
