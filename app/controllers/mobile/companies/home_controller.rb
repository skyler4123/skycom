class Mobile::Companies::HomeController < Mobile::Companies::BaseController
  def index
    @company_utc_offset = company_utc_offset
    company_now = Time.current.getlocal(@company_utc_offset)
    company_today = company_now.to_date

    @attendance_month = @employee.attendance_months.find_by(month: company_today.beginning_of_month)
    @today_shift = @employee.scheduled_shifts.find_by(work_date: company_today)
    @today_logs = @employee.attendance_logs.includes(:branch).where(logged_at: company_now.all_day).order(:logged_at).to_a
    @check_in_logs = @today_logs.select(&:log_type_check_in?)
    @checked_in = @check_in_logs.any?
    @pending_requests_count = AttendanceRequest.where(employee: @employee, status: :pending).count
    @current_payroll = @employee.payrolls.find_by(month: company_today.beginning_of_month)
    @attendance_balance = AttendanceBalance.for(employee: @employee, year: company_today.year)
    @announcement = @employee.documents.announcements.published.order(updated_at: :desc).first
  end
end
