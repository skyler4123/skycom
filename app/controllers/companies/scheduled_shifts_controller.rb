# app/controllers/companies/scheduled_shifts_controller.rb
#
# Scheduled shift dashboard API (Shell-First).
# Serves Stimulus: Companies_ScheduledShifts_IndexController, Companies_ScheduledShifts_ShowController,
#                  Companies_ScheduledShifts_NewController, Companies_ScheduledShifts_EditController
# Endpoints: GET /companies/:company_id/scheduled_shifts(.json?employee_name&status&from&to)
# Docs: docs/HR.md
class Companies::ScheduledShiftsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.scheduled_shifts.includes(:employee, :shift_template)
        scope = scope.where(employee_id: params[:employee_id]) if params[:employee_id].present?
        scope = scope.joins(:employee).where("employees.name ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:employee_name].strip)}%") if params[:employee_name].present?
        from = parse_filter_date(params[:from])
        scope = scope.where("work_date >= ?", from) if from
        to = parse_filter_date(params[:to])
        scope = scope.where("work_date <= ?", to) if to
        scope = scope.where(status: params[:status]) if ScheduledShift.statuses.key?(params[:status].to_s)
        @pagy, @results = pagy(:offset, scope.order(work_date: :asc, expected_start_at: :asc), jsonapi: true)
        render json: { scheduled_shifts: @results.map { |s| format_shift(s) }, pagination: @pagy.data_hash }
      end
    end
  end

  def show
    ss = current_company.scheduled_shifts.find(params[:id])
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { scheduled_shift: format_shift(ss) } }
    end
  end

  def new
    respond_to { |f| f.html { render html: "", layout: true } }
  end

  def edit
    ss = current_company.scheduled_shifts.find(params[:id])
    respond_to { |f| f.html { render html: "", layout: true } }
  end

  def create
    ss = current_company.scheduled_shifts.new(ss_params)
    if ss.save
      redirect_to company_scheduled_shift_path(current_company, ss), notice: "Scheduled shift created"
    else
      redirect_to new_company_scheduled_shift_path(current_company), alert: ss.errors.full_messages.to_sentence
    end
  end

  def update
    ss = current_company.scheduled_shifts.find(params[:id])
    if ss.update(ss_params)
      redirect_to company_scheduled_shift_path(current_company, ss), notice: "Updated"
    else
      redirect_to edit_company_scheduled_shift_path(current_company, ss), alert: ss.errors.full_messages.to_sentence
    end
  end

  private

  def parse_filter_date(value)
    Date.parse(value.to_s)
  rescue ArgumentError, TypeError, Date::Error
    nil
  end

  def ss_params
    params.require(:scheduled_shift).permit(:employee_id, :shift_template_id, :branch_id, :work_date, :expected_start_at, :expected_end_at, :status)
  end

  def format_shift(s)
    s.as_json(only: %i[id employee_id branch_id shift_template_id work_date expected_start_at expected_end_at status created_at]).merge(
      employee: s.employee.as_json(only: %i[id name]),
      shift_template: s.shift_template.as_json(only: %i[id name])
    )
  end
end
