class Companies::AttendanceLogsController < Companies::ApplicationController
  feature_key :hrm_attendance

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.attendance_logs.includes(:employee).order(logged_at: :desc)
        scope = scope.where(employee_id: params[:employee_id]) if params[:employee_id].present?
        scope = scope.where(log_type: params[:log_type]) if params[:log_type].present?
        scope = scope.where("logged_at >= ?", params[:from]) if params[:from].present?
        scope = scope.where("logged_at <= ?", params[:to]) if params[:to].present?
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

  def format_log(l)
    l.as_json(only: %i[id log_type logged_at latitude longitude wifi_ssid device_fingerprint created_at]).merge(
      employee: l.employee.as_json(only: %i[id name])
    )
  end
end
