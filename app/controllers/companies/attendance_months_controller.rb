class Companies::AttendanceMonthsController < Companies::ApplicationController
  feature_key :hrm_attendance

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.attendance_months.includes(:employee).order(month: :desc)
        scope = scope.where(employee_id: params[:employee_id]) if params[:employee_id].present?
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

  def format_month(m)
    m.as_json(only: %i[id month total_work_minutes total_late_minutes total_early_leave_minutes total_overtime_minutes total_absent_days total_present_days total_deficit_minutes created_at]).merge(
      employee: m.employee.as_json(only: %i[id name])
    )
  end
end
