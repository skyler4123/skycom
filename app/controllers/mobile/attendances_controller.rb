class Mobile::AttendancesController < Mobile::BaseController
  def create
    employee = current_user.employees.first

    unless employee
      redirect_to mobile_home_path, alert: "No employee record found" and return
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
