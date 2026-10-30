class Mobile::Companies::EmployeesController < Mobile::Companies::BaseController
  def show
    @attendance_month = @employee.attendance_months.find_by(month: Date.current.beginning_of_month)
    @next_shift = @employee.scheduled_shifts.where(work_date: Date.current..).order(:work_date).first
    @manager = @employee.manager
    @contract_renewal = @employee.expiration_date
  end

  private

  def employee_includes
    super + %i[roles departments category manager]
  end
end
