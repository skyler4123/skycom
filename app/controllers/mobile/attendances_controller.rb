class Mobile::AttendancesController < Mobile::BaseController
  def create
    employee = current_user.employees.first

    unless employee
      redirect_to mobile_home_path, alert: "No employee record found" and return
    end

    if employee.attendance_logs.where(logged_at: Date.current.all_day, log_type: :check_in).exists?
      redirect_to mobile_home_path, alert: "Already checked in today" and return
    end

    branch = employee.branch || employee.company.branches.first

    AttendanceLog.create!(
      company: employee.company,
      branch: branch,
      employee: employee,
      log_type: :check_in,
      logged_at: Time.current
    )

    redirect_to mobile_home_path, notice: "Checked in successfully"
  end
end
