# frozen_string_literal: true

# Mobile::Companies::PayrollsController — Shell-First payroll screen for the
# signed-in employee. The password gate still guards the JSON payload; the shell
# only loads once the five-minute unlock exists.
# Serves Stimulus: Mobile_Companies_Payrolls_ShowController
# Endpoints: GET /mobile/companies/:company_id/payroll(.json?month=YYYY-MM)
# Docs: docs/MOBILE.md §2-§4
class Mobile::Companies::PayrollsController < Mobile::Companies::BaseController
  before_action :require_payroll_unlock, only: :show

  def show
    @month = parse_month(params[:month]) || Date.current.beginning_of_month
    @payroll = Payroll.where(employee: @employee)
      .where(month: @month.beginning_of_month..@month.end_of_month)
      .includes(:attendance_month)
      .first
    @attendance_month = @payroll&.attendance_month
    @month_options = (0..11).map { |offset| Date.current.beginning_of_month - offset.months }
    @month_options << @month unless @month_options.include?(@month)
    @month_options.sort!.reverse!
    @status_step = { "draft" => 1, "approved" => 2, "paid" => 3 }[@payroll&.status] || 1

    respond_to do |format|
      format.html do
        @page_title = "Payroll"
        render_mobile_shell(
          json_url: mobile_company_payroll_path(@company, month: params[:month].presence, format: :json)
        )
      end
      format.json { render json: payroll_payload }
    end
  end

  private

  def payroll_payload
    {
      employee: { name: @employee.name, branch_name: @employee.branch&.name },
      company: { id: @company.id, name: @company.name },
      month: @month.iso8601,
      period_start: @month.beginning_of_month.iso8601,
      period_end: @month.end_of_month.iso8601,
      period_days: @month.end_of_month.day,
      disbursement_date: (@month.end_of_month + 2.days).iso8601,
      month_options: @month_options.map { |month| { value: month.strftime("%Y-%m") } },
      payroll: @payroll && payroll_record_payload,
      attendance_month: @attendance_month && {
        total_work_minutes: @attendance_month.total_work_minutes.to_i,
        total_present_days: @attendance_month.total_present_days.to_i,
        total_overtime_minutes: @attendance_month.total_overtime_minutes.to_i
      },
      status_step: @status_step,
      payroll_tax_percent: ((PAYROLL_TAX_RATE + PAYROLL_SOCIAL_INSURANCE_RATE) * 100).round(1)
    }
  end

  def payroll_record_payload
    {
      status: @payroll.status,
      currency: @payroll.currency,
      base_amount_cents: @payroll.base_amount_cents,
      allowance_amount_cents: @payroll.allowance_amount_cents,
      overtime_amount_cents: @payroll.overtime_amount_cents,
      gross_amount_cents: @payroll.gross_amount_cents,
      total_deductions_cents: @payroll.total_deductions_cents,
      net_amount_cents: @payroll.net_amount_cents
    }
  end

  def require_payroll_unlock
    return if payroll_unlocked?

    redirect_to mobile_company_payroll_unlock_path(@company, month: params[:month])
  end

  def payroll_unlocked?
    session[:mobile_payroll_unlock_company_id] == @company.id &&
      session[:mobile_payroll_unlock_expires_at].to_i > Time.current.to_i
  end

  def parse_month(value)
    return nil if value.blank?

    Date.parse("#{value}-01")
  rescue ArgumentError, TypeError, Date::Error
    nil
  end
end
