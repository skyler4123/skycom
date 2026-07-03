class Companies::AttendancesController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.attendance_records.includes(:employee)
        scope = scope.where(employee_id: params[:employee_id]) if params[:employee_id].present?
        scope = scope.where("check_in_at >= ?", params[:from]) if params[:from].present?
        scope = scope.where("check_in_at <= ?", params[:to]) if params[:to].present?
        @pagy, @results = pagy(:offset, scope.order(check_in_at: :desc), jsonapi: true)
        render json: { attendance_records: @results.map { |r| format_record(r) }, pagination: @pagy.data_hash }
      end
    end
  end

  def show
    record = current_company.attendance_records.find(params[:id])
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { attendance_record: format_record(record) } }
    end
  end

  private

  def format_record(r)
    r.as_json(only: %i[id check_in_at check_out_at total_work_minutes late_minutes early_leave_minutes overtime_minutes computed_status]).merge(
      employee: r.employee.as_json(only: %i[id name])
    )
  end
end
