# app/controllers/companies/performance_controller.rb
#
# Employee KPI visibility: company leaderboard (index) and one employee's
# scorecard (show). Read-only, computed on demand for the selected period.
# Authorization is ABAC through Companies::PerformancePolicy, which requires
# KpiConfig read (owner full access; Manager seeded read-only).
# Serves Stimulus: Companies_Performance_IndexController,
#                  Companies_Performance_ShowController
# Endpoints: GET /companies/:company_id/performance(.json),
#            GET /companies/:company_id/performance/:id(.json)
# Docs: docs/KPI.md
class Companies::PerformanceController < Companies::ApplicationController
  def index
    range = period_range

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: Kpi::LeaderboardService.call(
          company: current_company,
          from: range.from,
          to: range.to
        ).merge(
          period: period_payload(range),
          can_manage: current_employee.can?(:create, KpiConfig)
        )
      end
    end
  end

  def show
    employee = current_company.employees.where(discarded_at: nil).find(params[:id])
    range = period_range

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: Kpi::ScorecardService.call(
          company: current_company,
          employee: employee,
          from: range.from,
          to: range.to
        ).merge(
          period: period_payload(range),
          can_manage: current_employee.can?(:create, KpiConfig)
        )
      end
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to company_performance_index_path(current_company), alert: "Employee not found" }
      format.json { render json: { errors: [ "Employee not found" ] }, status: :not_found }
    end
  end

  private

  def period_range
    Kpi::PeriodRange.new(period: params[:period], from: params[:from], to: params[:to])
  end

  def period_payload(range)
    { key: range.key, from: range.from.iso8601, to: range.to.iso8601 }
  end
end
