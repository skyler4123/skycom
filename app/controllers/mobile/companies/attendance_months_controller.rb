# frozen_string_literal: true

# Mobile::Companies::AttendanceMonthsController — Shell-First attendance month
# for the signed-in employee. The shell hydrates month totals and every daily
# record from .json; nothing is server-rendered.
# Serves Stimulus: Mobile_Companies_AttendanceMonths_ShowController
# Endpoints: GET /mobile/companies/:company_id/attendance_month(.json?month=YYYY-MM)
# Docs: docs/MOBILE.md §2-§3
class Mobile::Companies::AttendanceMonthsController < Mobile::Companies::BaseController
  def show
    @month = parse_month(params[:month]) || Date.current.beginning_of_month
    @attendance_month = AttendanceMonth.find_by(employee: @employee, month: @month.beginning_of_month)
    @attendance_days = @employee.attendance_days
      .where(attendance_date: @month.beginning_of_month..@month.end_of_month)
      .order(:attendance_date)
    @prev_month = @month - 1.month
    @next_month = @month + 1.month
    @next_disabled = @next_month > Date.current.beginning_of_month

    respond_to do |format|
      format.html do
        @page_title = "Attendance"
        render_mobile_shell(
          json_url: mobile_company_attendance_month_path(
            @company,
            month: params[:month].presence,
            format: :json
          )
        )
      end
      format.json { render json: month_payload }
    end
  end

  private

  def month_payload
    {
      employee: { name: @employee.name, branch_name: @employee.branch&.name },
      company: { id: @company.id, name: @company.name },
      month: @month.iso8601,
      current_month: @month == Date.current.beginning_of_month,
      attendance_month: @attendance_month && attendance_month_payload,
      attendance_days: @attendance_days.map { |day| attendance_day_payload(day) },
      prev_month: @prev_month.strftime("%Y-%m"),
      next_month: @next_month.strftime("%Y-%m"),
      next_disabled: @next_disabled
    }
  end

  def attendance_month_payload
    {
      total_work_minutes: @attendance_month.total_work_minutes.to_i,
      total_present_days: @attendance_month.total_present_days.to_i,
      total_absent_days: @attendance_month.total_absent_days.to_i,
      total_overtime_minutes: @attendance_month.total_overtime_minutes.to_i,
      total_records: @attendance_month.total_records.to_i
    }
  end

  def attendance_day_payload(day)
    {
      attendance_date: day.attendance_date,
      recorded_method: day.recorded_method,
      attendance_status: day.attendance_status,
      check_in: day.check_in,
      check_out: day.check_out,
      total_seconds_worked: day.total_seconds_worked.to_i
    }
  end

  def parse_month(value)
    return nil if value.blank?

    Date.parse("#{value}-01")
  rescue ArgumentError, TypeError, Date::Error
    nil
  end
end
