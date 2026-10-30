# frozen_string_literal: true

module Payrolls
  class GenerateService
    def initialize(company:, month:, payroll_config: nil)
      @company = company
      @month = month.to_date.beginning_of_month
      @config = payroll_config || PayrollConfig.for_company!(company)
    end

    def call
      scope = @company.attendance_months.where(month: @month.beginning_of_month..@month.end_of_month)
      scope = scope.where(branch_id: @config.branch_ids) if @config.branch_ids.present?
      scope = scope.where(employee_id: @config.employee_ids) if @config.employee_ids.present?

      scope.includes(:employee, :branch).find_each do |am|
        attrs = {
          company: @company,
          branch: am.branch,
          employee: am.employee,
          attendance_month: am,
          month: am.month.to_date.beginning_of_month,
          payroll_config: @config,
          metadata: build_metadata(am),
          currency: am.employee.currency,
          status: :draft
        }.merge(build_amounts(am))
        payroll = Payroll.find_or_initialize_by(company: @company, employee: am.employee, month: attrs[:month])
        payroll.assign_attributes(attrs.except(:company, :employee, :month))
        payroll.save!
      end
    end

    private

    def build_amounts(am)
      working_days = working_days_in_month
      ratio = working_days.zero? ? 0.0 : [ am.total_present_days.to_f / working_days, 1.0 ].min
      salary = am.employee.monthly_salary_cents.to_i
      allowance = am.employee.monthly_allowance_cents.to_i

      base = (salary * ratio).round
      allowance_amount = (allowance * ratio).round
      overtime = (
        salary * 12.0 / PAYROLL_ANNUAL_WORK_MINUTES *
        am.total_overtime_minutes.to_i * PAYROLL_OVERTIME_MULTIPLIER
      ).round
      gross = base + allowance_amount + overtime
      tax = (gross * PAYROLL_TAX_RATE).round
      deduction = (gross * PAYROLL_SOCIAL_INSURANCE_RATE).round

      {
        base_amount_cents: base,
        allowance_amount_cents: allowance_amount,
        overtime_amount_cents: overtime,
        gross_amount_cents: gross,
        tax_amount_cents: tax,
        deduction_amount_cents: deduction,
        net_amount_cents: gross - tax - deduction
      }
    end

    def working_days_in_month
      (@month.beginning_of_month..@month.end_of_month).count { |date| (1..5).cover?(date.wday) }
    end

    def build_metadata(am)
      {
        "attendance_month_id" => am.id,
        "total_work_minutes" => am.total_work_minutes,
        "total_late_minutes" => am.total_late_minutes,
        "total_early_leave_minutes" => am.total_early_leave_minutes,
        "total_overtime_minutes" => am.total_overtime_minutes,
        "total_absent_days" => am.total_absent_days,
        "total_present_days" => am.total_present_days,
        "total_records" => am.total_records,
        "total_deficit_minutes" => am.total_deficit_minutes,
        "config" => {
          "date_basis" => @config.date_basis,
          "branch_ids" => @config.branch_ids,
          "employee_ids" => @config.employee_ids,
          "business_types" => @config.business_types
        }
      }
    end
  end
end
