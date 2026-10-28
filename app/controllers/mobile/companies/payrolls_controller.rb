class Mobile::Companies::PayrollsController < Mobile::Companies::BaseController
  def show
    @month = parse_month(params[:month]) || Date.current.beginning_of_month
    @payroll = Payroll.where(employee: @employee).where(month: @month.beginning_of_month..@month.end_of_month).includes(:attendance_month).first
    @attendance_month = @payroll&.attendance_month
    @month_options = (0..11).map { |offset| Date.current.beginning_of_month - offset.months }
    @month_options << @month unless @month_options.include?(@month)
    @month_options.sort!.reverse!
    @status_step = { "draft" => 1, "approved" => 2, "paid" => 3 }[@payroll&.status] || 1
    @progress_class = { 1 => "w-1/3", 2 => "w-2/3", 3 => "w-full" }[@status_step]
  end

  private

  def parse_month(value)
    return nil if value.blank?
    Date.parse("#{value}-01")
  rescue ArgumentError, TypeError, Date::Error
    nil
  end
end
