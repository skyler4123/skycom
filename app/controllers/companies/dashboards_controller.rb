# frozen_string_literal: true

# Companies::DashboardsController — company-health dashboard shell + JSON.
# Serves Stimulus: companies/dashboards/index_controller.js
#   GET /companies/:company_id/dashboards(.json)
#
# The JSON payload is cached in sync_cache for DASHBOARD_CACHE_EXPIRY (5 min)
# per company and financial-visibility level. Credit deduction still runs on
# every request through the after_action filter — caching never bypasses billing.
class Companies::DashboardsController < Companies::ApplicationController
  DASHBOARD_CACHE_EXPIRY = 5.minutes

  # Credit deduction is handled by the after_action filter — never inline.
  deduct_company_credits_for :index, with: CompanyCreditDeduction::Companies::Dashboards::IndexService

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        can_view_financials = current_employee.can?(:read, Invoice)
        payload = Rails.sync_cache.fetch(
          CacheKeyService.company_dashboard(current_company.id, can_view_financials: can_view_financials),
          expires_in: DASHBOARD_CACHE_EXPIRY
        ) do
          Dashboards::OverviewService.call(
            company: current_company,
            can_view_financials: can_view_financials
          )
        end

        render json: payload
      end
    end
  end
end
