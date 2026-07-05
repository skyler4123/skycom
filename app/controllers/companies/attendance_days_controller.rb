class Companies::AttendanceDaysController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.attendance_days.includes(:employee).order(attendance_date: :desc)
        scope = scope.where(employee_id: params[:employee_id]) if params[:employee_id].present?
        scope = scope.where("attendance_date >= ?", params[:from]) if params[:from].present?
        scope = scope.where("attendance_date <= ?", params[:to]) if params[:to].present?
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

  def format_day(d)
    d.as_json(only: %i[id attendance_date check_in check_out total_seconds_worked attendance_status]).merge(
      employee: d.employee.as_json(only: %i[id name])
    )
  end
end
