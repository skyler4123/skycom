# app/services/purchases/search_query_service.rb
#
# Purchases index search/filter — TableConfig-driven translation to Meilisearch.
# Depends on BE: Companies::PurchasesController#index (?q= / ?filters[key])
# Docs: docs/DYNAMIC_TABLE.md §2.5, docs/MEILISEARCH.md §4
class Purchases::SearchQueryService < DynamicSearch::BaseQueryService
  def self.model = Purchase

  def self.fallback_resource_name = "purchases"
end
