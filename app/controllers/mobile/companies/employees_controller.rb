# frozen_string_literal: true

# Mobile::Companies::EmployeesController — Shell-First employee profile for the
# signed-in employee. Identity, contact, assignment, attendance summary and the
# payroll entry point all hydrate from .json.
# Serves Stimulus: Mobile_Companies_Employees_ShowController
# Endpoints: GET /mobile/companies/:company_id/employee(.json)
# Docs: docs/MOBILE.md §2-§3
class Mobile::Companies::EmployeesController < Mobile::Companies::BaseController
  def show
    @attendance_month = @employee.attendance_months.find_by(month: Date.current.beginning_of_month)
    @next_shift = @employee.scheduled_shifts.where(work_date: Date.current..).order(:work_date).first
    @managers = @employee.managers
    @contract_renewal = @employee.expiration_date

    respond_to do |format|
      format.html do
        @page_title = "Profile"
        render_mobile_shell(json_url: mobile_company_employee_path(@company, format: :json))
      end
      format.json { render json: profile_payload }
    end
  end

  private

  def employee_includes
    super + %i[roles departments category]
  end

  def profile_payload
    {
      employee: {
        id: @employee.id,
        name: @employee.name,
        code: @employee.code,
        business_type: @employee.business_type,
        category_name: @employee.category&.name,
        roles: @employee.roles.map(&:name),
        departments: @employee.departments.map(&:name),
        branch_name: @employee.branch&.name,
        email: @employee.email,
        phone_number: @employee.phone_number,
        expiration_date: @contract_renewal&.to_date&.iso8601
      },
      managers: @managers.map { |manager| { name: manager.name } },
      user: {
        name: current_user.name.presence ||
          [ current_user.first_name, current_user.last_name ].compact.join(" ").presence,
        email: current_user.email,
        phone_number: current_user.phone_number,
        system_role_label: current_user.system_role&.titleize,
        username: current_user.username
      },
      company: { id: @company.id, name: @company.name },
      attendance_month: @attendance_month && {
        total_work_minutes: @attendance_month.total_work_minutes.to_i,
        total_present_days: @attendance_month.total_present_days.to_i,
        total_overtime_minutes: @attendance_month.total_overtime_minutes.to_i
      },
      next_shift: @next_shift && {
        work_date: @next_shift.work_date.iso8601,
        expected_start_at: @next_shift.expected_start_at,
        expected_end_at: @next_shift.expected_end_at
      }
    }
  end
end
