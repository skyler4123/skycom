# app/controllers/companies/attendance_months_controller.rb
#
# Attendance month dashboard API (Shell-First).
# Serves Stimulus: Companies_AttendanceMonths_IndexController, Companies_AttendanceMonths_ShowController
# Endpoints: GET /companies/:company_id/attendance_months(.json?employee_name&from&to&min_absent_days&min_deficit_minutes)
# Docs: docs/HR.md
class Companies::AttendanceMonthsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.attendance_months.includes(:employee).order(month: :desc)
        scope = scope.where(employee_id: params[:employee_id]) if params[:employee_id].present?
        scope = scope.joins(:employee).where("employees.name ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:employee_name].strip)}%") if params[:employee_name].present?
        from = parse_filter_date(params[:from])
        scope = scope.where("month >= ?", from) if from
        to = parse_filter_date(params[:to])
        scope = scope.where("month <= ?", to) if to
        min_absent = parse_filter_integer(params[:min_absent_days])
        scope = scope.where("total_absent_days >= ?", min_absent) if min_absent
        min_deficit = parse_filter_integer(params[:min_deficit_minutes])
        scope = scope.where("total_deficit_minutes >= ?", min_deficit) if min_deficit
        @pagy, @results = pagy(:offset, scope, jsonapi: true)
        render json: { attendance_months: @results.map { |m| format_month(m) }, pagination: @pagy.data_hash }
      end
    end
  end

  def show
    m = current_company.attendance_months.find(params[:id])
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { attendance_month: format_month(m) } }
    end
  end

  private

  def parse_filter_date(value)
    Date.parse(value.to_s)
  rescue ArgumentError, TypeError, Date::Error
    nil
  end

  def parse_filter_integer(value)
    return nil if value.blank?

    Integer(value.to_s, 10)
  rescue ArgumentError, TypeError
    nil
  end

  def format_month(m)
    m.as_json(only: %i[id month total_work_minutes total_late_minutes total_early_leave_minutes total_overtime_minutes total_absent_days total_present_days total_deficit_minutes created_at]).merge(
      employee: m.employee.as_json(only: %i[id name])
    )
  end
end
