# frozen_string_literal: true

# Companies::PayrollsController — payroll review + persisted payroll runs.
# Serves Stimulus: Companies_Payrolls_IndexController, Companies_Payrolls_ShowController, Companies_Payrolls_MyController
# Endpoints: GET /companies/:company_id/payroll(.json) + summary/payrolls/generate
class Companies::PayrollsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { payroll_config: format_payroll_config } }
    end
  end

  def summary
    config = PayrollConfig.for_company!(current_company)
    month = parse_month(params[:month]) || Date.current.beginning_of_month

    scope = scoped_payrolls(config, month)
    render json: {
      month: month.to_s,
      payroll_config: format_payroll_config(config),
      summary: {
        total: scope.count,
        draft: scope.where(status: :draft).count,
        approved: scope.where(status: :approved).count,
        paid: scope.where(status: :paid).count,
        total_net_amount_cents: scope.sum(:net_amount_cents),
        currency: current_company.currency
      }
    }
  end

  def payrolls
    config = PayrollConfig.for_company!(current_company)
    month = parse_month(params[:month]) || Date.current.beginning_of_month
    scope = scoped_payrolls(config, month)
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(branch_id: params[:branch_id]) if params[:branch_id].present?
    scope = scope.where(employee_id: params[:employee_id]) if params[:employee_id].present?
    @pagy, results = pagy(:offset, scope.includes(:employee, :branch), jsonapi: true)

    render json: {
      payrolls: results.map { |p| format_payroll(p) },
      pagination: @pagy.data_hash
    }
  end

  def show
    payroll = current_company.payrolls.find(params[:id])
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          payroll: format_payroll(payroll),
          attendance_month: payroll.attendance_month ? format_attendance_month(payroll.attendance_month) : nil,
          attendance_days: payroll.attendance_month ? attendance_days_for(payroll.attendance_month).map { |d| format_day(d) } : []
        }
      end
    end
  end

  def my
    employee = current_employee
    month = parse_month(params[:month]) || Date.current.beginning_of_month
    payroll = employee ? current_company.payrolls.where(employee: employee).where(month: month.beginning_of_month..month.end_of_month).first : nil
    payrolls = employee ? current_company.payrolls.where(employee: employee).order(month: :desc) : []
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          employee: employee&.as_json(only: %i[id name]),
          month: month.to_s,
          payroll: payroll ? format_payroll(payroll) : nil,
          attendance_month: payroll&.attendance_month ? format_attendance_month(payroll.attendance_month) : nil,
          attendance_days: payroll&.attendance_month ? attendance_days_for(payroll.attendance_month).map { |d| format_day(d) } : [],
          months: payrolls.map { |p| { id: p.id, month: p.month } }
        }
      end
    end
  end

  def generate
    config = PayrollConfig.for_company!(current_company)
    month = parse_month(params[:month]) || Date.current.beginning_of_month
    Payrolls::GenerateService.new(company: current_company, month: month, payroll_config: config).call
    render json: { message: "Payroll generated" }
  rescue StandardError => e
    render json: { errors: [ e.message ] }, status: :unprocessable_content
  end

  def update
    payroll = current_company.payrolls.find(params[:id])

    if payroll.update(payroll_params)
      respond_to do |format|
        format.html { redirect_to company_payroll_path(current_company), notice: "Payroll updated" }
        format.json { render json: { payroll: format_payroll(payroll) } }
      end
    else
      respond_to do |format|
        format.html { redirect_to company_payroll_path(current_company), alert: payroll.errors.full_messages.to_sentence }
        format.json { render json: { errors: payroll.errors.full_messages }, status: :unprocessable_content }
      end
    end
  end

  private

  def parse_month(value)
    return nil if value.blank?
    Date.parse("#{value}-01")
  rescue ArgumentError, TypeError, Date::Error
    nil
  end

  def scoped_payrolls(config, month)
    scope = current_company.payrolls.where(month: month.beginning_of_month..month.end_of_month)
    scope
  end

  def payroll_params
    params.require(:payroll).permit(:status, :notes)
  end

  def format_payroll_config(config = nil)
    config ||= PayrollConfig.for_company!(current_company)
    {
      id: config.id,
      date_basis: config.date_basis,
      include_attendance_months: config.include_attendance_months,
      include_attendance_days: config.include_attendance_days,
      excluded_lifecycle_statuses: config.excluded_lifecycle_statuses,
      excluded_workflow_statuses: config.excluded_workflow_statuses,
      business_types: config.business_types,
      branch_ids: config.branch_ids,
      employee_ids: config.employee_ids
    }
  end

  def format_payroll(payroll)
    {
      id: payroll.id,
      month: payroll.month,
      status: payroll.status,
      notes: payroll.notes,
      employee: payroll.employee.as_json(only: [ :id, :name ]),
      branch: payroll.branch&.as_json(only: [ :id, :name ]),
      currency: payroll.currency,
      base_amount_cents: payroll.base_amount_cents,
      allowance_amount_cents: payroll.allowance_amount_cents,
      overtime_amount_cents: payroll.overtime_amount_cents,
      gross_amount_cents: payroll.gross_amount_cents,
      tax_amount_cents: payroll.tax_amount_cents,
      deduction_amount_cents: payroll.deduction_amount_cents,
      total_deductions_cents: payroll.total_deductions_cents,
      net_amount_cents: payroll.net_amount_cents,
      metadata: payroll.metadata,
      created_at: payroll.created_at,
      updated_at: payroll.updated_at
    }
  end

  def format_attendance_month(m)
    m.as_json(only: %i[id month total_work_minutes total_late_minutes total_early_leave_minutes total_overtime_minutes total_absent_days total_present_days total_deficit_minutes created_at])
  end

  def attendance_days_for(m)
    return AttendanceDay.none if m.month.blank?

    month_date = m.month.to_date
    current_company.attendance_days.includes(:employee)
      .where(employee_id: m.employee_id, attendance_date: month_date.beginning_of_month..month_date.end_of_month)
      .order(attendance_date: :asc)
  end

  def format_day(d)
    d.as_json(only: %i[id attendance_date check_in check_out total_seconds_worked attendance_status])
  end
end
