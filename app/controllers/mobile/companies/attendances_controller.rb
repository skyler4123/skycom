class Mobile::Companies::AttendancesController < Mobile::Companies::BaseController
  def create
    if @employee.attendance_logs.where(logged_at: Date.current.all_day, log_type: :check_in).exists?
      redirect_to mobile_company_home_path(@company), alert: "Already checked in today"
      return
    end

    branch = @employee.branch || @employee.company.branches.first

    AttendanceLog.create!(
      company: @employee.company,
      branch: branch,
      employee: @employee,
      log_type: :check_in,
      logged_at: Time.current
    )

    redirect_to mobile_company_home_path(@company), notice: "Checked in successfully"
  end
end
