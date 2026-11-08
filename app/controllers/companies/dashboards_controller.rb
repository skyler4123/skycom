# frozen_string_literal: true

# Companies::DashboardsController — company-health dashboard shell + JSON,
# plus the Dashboard Config page (show/update).
# Serves Stimulus: companies/dashboards/index_controller.js
#   GET /companies/:company_id/dashboards(.json)
# Serves Stimulus: companies/dashboards/show_controller.js
#   GET/PATCH /companies/:company_id/dashboard(.json)
#
# The index JSON payload is cached in sync_cache for DASHBOARD_CACHE_EXPIRY (5 min)
# per company and financial-visibility level. Credit deduction still runs on
# every request through the after_action filter — caching never bypasses billing.
# Dashboard config updates clear both cached payloads so the next visit reflects
# the new block list immediately.
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

  # Settings page that edits the company's first dashboard record.
  def show
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { dashboard: dashboard_payload(current_company.dashboard) } }
    end
  end

  def update
    dashboard = current_company.dashboard

    respond_to do |format|
      if dashboard.update(dashboard_attributes)
        clear_dashboard_cache
        format.html do
          redirect_to company_dashboard_path(current_company),
            notice: "Dashboard updated successfully"
        end
        format.json do
          render json: {
            dashboard: dashboard_payload(dashboard),
            message: "Dashboard updated successfully"
          }
        end
      else
        format.html do
          redirect_to company_dashboard_path(current_company),
            alert: dashboard.errors.full_messages.to_sentence
        end
        format.json do
          render json: { errors: dashboard.errors.full_messages }, status: :unprocessable_content
        end
      end
    end
  end

  private

  def dashboard_attributes
    source = params[:dashboard] || {}
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

  def dashboard_payload(dashboard)
    dashboard.as_json(
      only: %i[id name description workflow_status metadata created_at updated_at]
    ).merge(
      "blocks" => dashboard.active_blocks,
      "available_blocks" => Dashboard::BLOCKS
    )
  end

  def clear_dashboard_cache
    [ true, false ].each do |can_view_financials|
      Rails.sync_cache.delete(
        CacheKeyService.company_dashboard(
          current_company.id,
          can_view_financials: can_view_financials
        )
      )
    end
  end
end
