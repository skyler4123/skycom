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

      scope.find_each do |am|
        attrs = {
          company: @company,
          branch: am.branch,
          employee: am.employee,
          attendance_month: am,
          month: am.month.to_date.beginning_of_month,
          payroll_config: @config,
          metadata: build_metadata(am),
          status: :draft
        }
        payroll = Payroll.find_or_initialize_by(company: @company, employee: am.employee, month: attrs[:month])
        payroll.assign_attributes(attrs.except(:company, :employee, :month))
        payroll.save!
      end
    end

    private

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
