class Mobile::PayrollsController < Mobile::BaseController
  def show
    @employee = current_user.employees.first

    unless @employee
      redirect_to mobile_home_path, alert: "No employee record found" and return
    end

    @month = parse_month(params[:month]) || Date.current.beginning_of_month
    @payroll = Payroll.where(employee: @employee).where(month: @month.beginning_of_month..@month.end_of_month).first
    @months = Payroll.where(employee: @employee).order(month: :desc)
  end

  private

  def parse_month(value)
    return nil if value.blank?
    Date.parse("#{value}-01")
  rescue ArgumentError, TypeError, Date::Error
    nil
  end
end
