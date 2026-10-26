class Mobile::EmployeesController < Mobile::BaseController
  def show
    @employee = current_user.employees.includes(:company, :branch, :roles, :departments, :category).first

    unless @employee
      redirect_to mobile_home_path, alert: "No employee record found" and return
    end

    @company = @employee.company
    @attendance_month = @employee.attendance_months.find_by(month: Date.current.beginning_of_month)
    @next_shift = @employee.scheduled_shifts.where(work_date: Date.current..).order(:work_date).first
  end
end
