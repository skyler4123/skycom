class Mobile::AttendanceMonthsController < Mobile::BaseController
  def show
    @employee = current_user.employees.first

    unless @employee
      redirect_to mobile_home_path, alert: "No employee record found" and return
    end

    @month = parse_month(params[:month]) || Date.current.beginning_of_month
    @attendance_month = AttendanceMonth.find_by(employee: @employee, month: @month.beginning_of_month)
    @attendance_days = @attendance_month ? AttendanceDay.where(employee: @employee, attendance_date: @month.beginning_of_month..@month.end_of_month).order(:attendance_date) : []
    @months = AttendanceMonth.where(employee: @employee).order(month: :desc)
  end

  private

  def parse_month(value)
    return nil if value.blank?
    Date.parse("#{value}-01")
  rescue ArgumentError, TypeError, Date::Error
    nil
  end
end
