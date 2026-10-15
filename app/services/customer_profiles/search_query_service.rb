# frozen_string_literal: true

# app/services/customer_profiles/search_query_service.rb

class CustomerProfiles::SearchQueryService < DynamicSearch::BaseQueryService
  def self.model = CustomerProfile
  def self.fallback_resource_name = "customer_profiles"
end
