# app/controllers/companies/attendance_logs_controller.rb
#
# Attendance log dashboard API (Shell-First).
# Serves Stimulus: Companies_AttendanceLogs_IndexController, Companies_AttendanceLogs_ShowController
# Endpoints: GET /companies/:company_id/attendance_logs(.json?employee_name&log_type&from&to)
# Docs: docs/HR.md
class Companies::AttendanceLogsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.attendance_logs.includes(:employee).order(logged_at: :desc)
        scope = scope.where(employee_id: params[:employee_id]) if params[:employee_id].present?
        scope = scope.joins(:employee).where("employees.name ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:employee_name].strip)}%") if params[:employee_name].present?
        scope = scope.where(log_type: params[:log_type]) if AttendanceLog.log_types.key?(params[:log_type].to_s)
        from = parse_filter_time(params[:from])
        scope = scope.where("attendance_logs.logged_at >= ?", from) if from
        to = parse_filter_time(params[:to])
        scope = scope.where("attendance_logs.logged_at <= ?", to) if to
        @pagy, @results = pagy(:offset, scope, jsonapi: true)
        render json: { attendance_logs: @results.map { |l| format_log(l) }, pagination: @pagy.data_hash }
      end
    end
  end

  def show
    log = current_company.attendance_logs.find(params[:id])
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { attendance_log: format_log(log) } }
    end
  end

  private

  def parse_filter_time(value)
    return nil if value.blank?

    Time.zone.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end

  def format_log(l)
    l.as_json(only: %i[id log_type logged_at latitude longitude wifi_ssid device_fingerprint created_at]).merge(
      employee: l.employee.as_json(only: %i[id name])
    )
  end
end
