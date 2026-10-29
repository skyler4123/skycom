# frozen_string_literal: true

# app/controllers/companies/storage_statistics_controller.rb
#
# Storage Statistics overview (Shell-First). Aggregates StoredFile audit
# columns via Storage::StatisticsService, cached 1 hour in sync_cache —
# uploads/deletes do not bust it (accepted staleness; clear the
# "storage_statistics/<company_id>" key to refresh).
# Serves Stimulus: Companies_StorageStatistics_IndexController
# Endpoints: GET /companies/:company_id/storage_statistics(.json)
# Docs: docs/STORAGE.md
class Companies::StorageStatisticsController < Companies::ApplicationController
  # Single-file constant: stats page cache TTL (docs/CONSTANTS.md).
  STATISTICS_CACHE_EXPIRY = 1.hour

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        statistics = Rails.sync_cache.fetch(
          "storage_statistics/#{current_company.id}",
          expires_in: STATISTICS_CACHE_EXPIRY
        ) do
          Storage::StatisticsService.call(company: current_company)
        end

        render json: statistics
      end
    end
  end
end
