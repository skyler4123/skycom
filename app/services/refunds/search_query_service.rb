# app/services/refunds/search_query_service.rb
#
# Refunds index search/filter — TableConfig-driven translation to Meilisearch.
class Refunds::SearchQueryService < DynamicSearch::BaseQueryService
  def self.model = Refund

  def self.fallback_resource_name = "refunds"
end
