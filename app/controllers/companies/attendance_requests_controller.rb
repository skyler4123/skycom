# app/controllers/companies/attendance_requests_controller.rb
#
# Attendance request tickets (Shell-First): employees file a request when they
# cannot check in onsite; a Manager/Admin approves (creates the AttendanceDay
# via AttendanceRequests::ApproveService) or rejects. status/decided_*
# columns are NEVER permitted through create — only the decide services move
# them. employee is forced from current_employee (self-only in v1).
# Serves Stimulus: Companies_AttendanceRequests_IndexController (index JSON),
#                  Companies_AttendanceRequests_ShowController,
#                  Companies_AttendanceRequests_NewController
# Endpoints: GET /companies/:company_id/attendance_requests(.json),
#            POST /companies/:company_id/attendance_requests/:id/approve,
#            POST /companies/:company_id/attendance_requests/:id/reject
# Docs: docs/superpowers/specs/2026-10-08-attendance-request-design.md, docs/HR.md

class Companies::AttendanceRequestsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.attendance_requests.includes(:employee).order(attendance_date: :desc)
        scope = scope.where(employee_id: params[:employee_id]) if params[:employee_id].present?
        scope = scope.where(status: params[:status]) if params[:status].present?
        scope = scope.where("attendance_date >= ?", params[:from]) if params[:from].present?
        scope = scope.where("attendance_date <= ?", params[:to]) if params[:to].present?
        @pagy, @results = pagy(:offset, scope, jsonapi: true)
        render json: { attendance_requests: @results.map { |r| format_request(r) }, pagination: @pagy.data_hash }
      end
    end
  end

  def show
    attendance_request = current_company.attendance_requests.find(params[:id])
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          attendance_request: format_request(attendance_request),
          attendance_day: attendance_request.attendance_day&.as_json(only: %i[id attendance_date check_in check_out total_seconds_worked attendance_status])
        }
      end
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: {} }
    end
  end

  def create
    attendance_request = current_company.attendance_requests.new(request_params)
    attendance_request.employee = current_employee
    attendance_request.branch ||= current_employee&.branch
    attendance_request.status = :pending

    if attendance_request.save
      redirect_to company_attendance_request_path(current_company, attendance_request), notice: "Attendance request created successfully"
    else
      redirect_to new_company_attendance_request_path(current_company), alert: attendance_request.errors.full_messages.to_sentence
    end
  end

  def approve
    attendance_request = current_company.attendance_requests.find(params[:id])
    result = AttendanceRequests::ApproveService.call(request: attendance_request, approver: current_employee)

    if result[:success]
      render json: {
        message: "Attendance request approved",
        attendance_request: format_request(attendance_request.reload),
        attendance_day: result[:attendance_day].as_json(only: %i[id attendance_date check_in check_out total_seconds_worked attendance_status])
      }
    else
      render json: { errors: result[:errors] }, status: :unprocessable_content
    end
  end

  def reject
    attendance_request = current_company.attendance_requests.find(params[:id])
    result = AttendanceRequests::RejectService.call(
      request: attendance_request, approver: current_employee, note: params[:note]
    )

    if result[:success]
      render json: { message: "Attendance request rejected", attendance_request: format_request(attendance_request.reload) }
    else
      render json: { errors: result[:errors] }, status: :unprocessable_content
    end
  end

  private

  # status/decided_* deliberately NOT permitted — the decide services own them.
  # employee is forced from current_employee (self-only in v1).
  def request_params
    params.require(:attendance_request).permit(
      :attendance_date, :check_in, :check_out, :reason, :business_type, :branch_id
    )
  end

  def format_request(r)
    r.as_json(only: %i[id attendance_date check_in check_out reason status business_type decided_at decision_note created_at]).merge(
      employee: r.employee.as_json(only: %i[id name]),
      decided_by: r.decided_by&.as_json(only: %i[id name])
    )
  end
end
