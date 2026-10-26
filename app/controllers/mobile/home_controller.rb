class Mobile::HomeController < Mobile::BaseController
  def index
    @employee = current_user.employees.includes(:company, :branch, :roles).first
    return unless @employee

    @company = @employee.company
    @attendance_month = @employee.attendance_months.find_by(month: Date.current.beginning_of_month)
    @today_shift = @employee.scheduled_shifts.find_by(work_date: Date.current)
    @today_logs = @employee.attendance_logs.includes(:branch).where(logged_at: Date.current.all_day).order(:logged_at)
    @last_log = @today_logs.last
    @checked_in = @last_log&.log_type_check_in? || false
    @pending_requests_count = AttendanceRequest.where(employee: @employee, status: :pending).count
    @current_payroll = @employee.payrolls.find_by(month: Date.current.beginning_of_month)
  end
end
