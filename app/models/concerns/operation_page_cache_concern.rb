# frozen_string_literal: true

# OperationPageCacheConcern — Atomic purpose: keeps the Operations and
# Operation Configs index caches fresh.
#
# Why it exists: both index payloads are company-level and cached for a day,
# but operation, appointment, branch, and warehouse changes must be visible
# immediately.
# How it works: delete-based keys are evicted on save and destroy. The cache
# value is rebuilt lazily by the index controllers.
# Main associations: the includer must have a company_id column.
module OperationPageCacheConcern
  extend ActiveSupport::Concern

  included do
    after_save :clear_operation_page_caches
    after_destroy :clear_operation_page_caches
  end

  private

  def clear_operation_page_caches
    company_id = self[:company_id]
    return if company_id.blank?

    Rails.sync_cache.delete(CacheKeyService.company_operation_appointments(company_id))
    Rails.sync_cache.delete(CacheKeyService.company_operation_configs(company_id))
  end
end
