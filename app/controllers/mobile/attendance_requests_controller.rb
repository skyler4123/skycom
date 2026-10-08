class Mobile::AttendanceRequestsController < Mobile::BaseController
  def new
    @attendance_request = AttendanceRequest.new(attendance_date: Date.current)
  end

  def create
    employee = current_user.employees.first

    unless employee
      redirect_to mobile_home_path, alert: "No employee record found" and return
    end

    attendance_request = AttendanceRequest.new(request_params)
    attendance_request.company = employee.company
    attendance_request.branch ||= employee.branch
    attendance_request.employee = employee
    attendance_request.status = :pending

    if attendance_request.save
      redirect_to mobile_home_path, notice: "Attendance request submitted successfully"
    else
      redirect_to new_mobile_attendance_request_path, alert: attendance_request.errors.full_messages.to_sentence
    end
  end

  private

  def request_params
    params.require(:attendance_request).permit(
      :attendance_date, :check_in, :check_out, :reason, :business_type, :branch_id
    )
  end
end
