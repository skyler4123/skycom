# frozen_string_literal: true

# app/services/employee_subprofiles/search_query_service.rb

class EmployeeSubprofiles::SearchQueryService < DynamicSearch::BaseQueryService
  def self.model = EmployeeSubprofile
  def self.fallback_resource_name = "employee_subprofiles"
end
