# frozen_string_literal: true

# Companies::AnalyticsController — executive analysis shell + JSON, plus the
# Analytics Config page (show/update).
# Serves Stimulus: companies/analytics/index_controller.js
#   GET /companies/:company_id/analytics(.json)?period=this_month|last_month|last_6_months|this_year
# Serves Stimulus: companies/analytics/show_controller.js
#   GET/PATCH /companies/:company_id/analytic(.json)
#
# The index JSON payload is cached in sync_cache for CACHE_DEFAULT_EXPIRY (1 hour)
# per company and period. Analytics config updates clear every cached period so
# the next visit reflects the new block list immediately.
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

  # Settings page that edits the company's first analytic record.
  def show
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { analytic: analytic_payload(current_company.analytic) } }
    end
  end

  def update
    analytic = current_company.analytic

    respond_to do |format|
      if analytic.update(analytic_attributes)
        clear_analytics_cache
        format.html do
          redirect_to company_analytic_path(current_company),
            notice: "Analytics updated successfully"
        end
        format.json do
          render json: {
            analytic: analytic_payload(analytic),
            message: "Analytics updated successfully"
          }
        end
      else
        format.html do
          redirect_to company_analytic_path(current_company),
            alert: analytic.errors.full_messages.to_sentence
        end
        format.json do
          render json: { errors: analytic.errors.full_messages }, status: :unprocessable_content
        end
      end
    end
  end

  private

  def analytic_attributes
    source = params[:analytic] || {}
    attrs = {}
    attrs[:name] = source[:name] if source.key?(:name)
    attrs[:description] = source[:description] if source.key?(:description)

    if source.key?(:blocks)
      raw = source[:blocks]
      raw = raw.values if raw.is_a?(ActionController::Parameters) || raw.is_a?(Hash)
      attrs[:blocks] = Array(raw).map(&:to_s).reject(&:blank?)
    end

    attrs
  end

  def analytic_payload(analytic)
    analytic.as_json(
      only: %i[id name description workflow_status metadata created_at updated_at]
    ).merge(
      "blocks" => analytic.active_blocks,
      "available_blocks" => Analytic::BLOCKS
    )
  end

  def clear_analytics_cache
    CacheKeyService::ANALYTICS_PERIODS.each do |period|
      Rails.sync_cache.delete(
        CacheKeyService.company_analytics(current_company.id, period)
      )
    end
  end
end
