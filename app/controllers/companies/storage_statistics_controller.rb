# frozen_string_literal: true

# app/controllers/companies/storage_statistics_controller.rb
#
# Storage Statistics overview (Shell-First). Aggregates StoredFile audit
# columns via Storage::StatisticsService, cached for CACHE_DEFAULT_EXPIRY in
# sync_cache — uploads/deletes do not bust it (accepted staleness; clear
# CacheKeyService.company_storage_statistics(company_id) to refresh).
# Serves Stimulus: Companies_StorageStatistics_IndexController
# Endpoints: GET /companies/:company_id/storage_statistics(.json)
# Docs: docs/STORAGE.md
class Companies::StorageStatisticsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        statistics = Rails.sync_cache.fetch(
          CacheKeyService.company_storage_statistics(current_company.id),
          expires_in: CACHE_DEFAULT_EXPIRY
        ) do
          Storage::StatisticsService.call(company: current_company)
        end

        render json: statistics
      end
    end
  end
end
