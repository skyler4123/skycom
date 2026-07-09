# frozen_string_literal: true

class Companies::AnalyticsController < Companies::ApplicationController
  feature_key :analytics_dashboard

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        period = params[:period] || "this_month"
        data = Rails.local_cache.fetch("analytics/#{current_company.id}/#{period}", expires_in: 5.minutes) do
          Analytics::DashboardService.call(company: current_company, period: period)
        end
        render json: data
      end
    end
  end
end
