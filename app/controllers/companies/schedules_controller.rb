class Companies::SchedulesController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.scheduled_shifts.includes(:employee, :shift_template)
        scope = scope.where(employee_id: params[:employee_id]) if params[:employee_id].present?
        scope = scope.where("work_date >= ?", params[:from]) if params[:from].present?
        scope = scope.where("work_date <= ?", params[:to]) if params[:to].present?
        scope = scope.where(status: params[:status]) if params[:status].present?
        @pagy, @results = pagy(:offset, scope.order(work_date: :asc, expected_start_at: :asc), jsonapi: true)
        render json: { scheduled_shifts: @results.map { |s| format_shift(s) }, pagination: @pagy.data_hash }
      end
    end
  end

  private

  def format_shift(s)
    {
      id: s.id,
      employee_name: s.employee&.name,
      shift_template_name: s.shift_template&.name,
      work_date: s.work_date,
      expected_start_at: s.expected_start_at,
      expected_end_at: s.expected_end_at,
      status: s.status
    }
  end
end
