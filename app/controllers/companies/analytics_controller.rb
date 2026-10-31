# frozen_string_literal: true

# Companies::AnalyticsController — executive analysis shell + JSON.
# Serves Stimulus: companies/analytics/index_controller.js
#   GET /companies/:company_id/analytics(.json)?period=this_month|last_month|last_6_months|this_year
class Companies::AnalyticsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        period = params[:period] || "this_month"
        data = Rails.sync_cache.fetch(
          CacheKeyService.company_analytics(current_company.id, period),
          expires_in: CACHE_DEFAULT_EXPIRY
        ) do
          Analytics::DashboardService.call(company: current_company, period: period)
        end
        render json: data
      end
    end
  end
end
