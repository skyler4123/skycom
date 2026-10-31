# frozen_string_literal: true

# Companies::DashboardsController — company-health dashboard shell + JSON.
# Serves Stimulus: companies/dashboards/index_controller.js
#   GET /companies/:company_id/dashboards(.json)
class Companies::DashboardsController < Companies::ApplicationController
  # Credit deduction is handled by the after_action filter — never inline.
  deduct_company_credits_for :index, with: CompanyCreditDeduction::Companies::Dashboards::IndexService

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: Dashboards::OverviewService.call(
          company: current_company,
          can_view_financials: current_employee.can?(:read, Invoice)
        )
      end
    end
  end
end
