class Mobile::AttendanceMonthsController < Mobile::BaseController
  def show
    @employee = current_user.employees.includes(:company, :branch).first

    unless @employee
      redirect_to mobile_home_path, alert: "No employee record found" and return
    end

    @company = @employee.company
    @month = parse_month(params[:month]) || Date.current.beginning_of_month
    @attendance_month = AttendanceMonth.find_by(employee: @employee, month: @month.beginning_of_month)
    @attendance_days = @employee.attendance_days.where(attendance_date: @month.beginning_of_month..@month.end_of_month).order(:attendance_date)
    @prev_month = @month - 1.month
    @next_month = @month + 1.month
    @next_disabled = @next_month > Date.current.beginning_of_month
  end

  private

  def parse_month(value)
    return nil if value.blank?
    Date.parse("#{value}-01")
  rescue ArgumentError, TypeError, Date::Error
    nil
  end
end
