# app/controllers/companies/attendance_days_controller.rb
#
# Attendance day dashboard API (Shell-First).
# Serves Stimulus: Companies_AttendanceDays_IndexController, Companies_AttendanceDays_ShowController
# Endpoints: GET /companies/:company_id/attendance_days(.json?employee_name&attendance_status&from&to)
# Docs: docs/HR.md
class Companies::AttendanceDaysController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.attendance_days.includes(:employee).order(attendance_date: :desc)
        scope = scope.where(employee_id: params[:employee_id]) if params[:employee_id].present?
        scope = scope.joins(:employee).where("employees.name ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:employee_name].strip)}%") if params[:employee_name].present?
        scope = scope.where(attendance_status: params[:attendance_status]) if AttendanceDay.attendance_statuses.key?(params[:attendance_status].to_s)
        from = parse_filter_date(params[:from])
        scope = scope.where("attendance_date >= ?", from) if from
        to = parse_filter_date(params[:to])
        scope = scope.where("attendance_date <= ?", to) if to
        @pagy, @results = pagy(:offset, scope, jsonapi: true)
        render json: { attendance_days: @results.map { |d| format_day(d) }, pagination: @pagy.data_hash }
      end
    end
  end

  def show
    day = current_company.attendance_days.find(params[:id])
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { attendance_day: format_day(day) } }
    end
  end

  private

  def parse_filter_date(value)
    Date.parse(value.to_s)
  rescue ArgumentError, TypeError, Date::Error
    nil
  end

  def format_day(d)
    d.as_json(only: %i[id attendance_date check_in check_out total_seconds_worked attendance_status]).merge(
      employee: d.employee.as_json(only: %i[id name])
    )
  end
end
