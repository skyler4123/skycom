# frozen_string_literal: true

# app/services/customer_subprofiles/search_query_service.rb

class CustomerSubprofiles::SearchQueryService < DynamicSearch::BaseQueryService
  def self.model = CustomerSubprofile
  def self.fallback_resource_name = "customer_subprofiles"
end
