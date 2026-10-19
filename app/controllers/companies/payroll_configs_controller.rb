# frozen_string_literal: true

# Companies::PayrollConfigsController — company-level payroll rebuild configuration.
# Serves Stimulus: Companies_PayrollConfigs_ShowController
# Endpoints: GET/PATCH /companies/:company_id/payroll_config(.json)
class Companies::PayrollConfigsController < Companies::ApplicationController
  def show
    config = PayrollConfig.for_company!(current_company)

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { payroll_config: format_config(config) } }
    end
  end

  def update
    config = PayrollConfig.for_company!(current_company)

    if config.update(payroll_config_params)
      respond_to do |format|
        format.html { redirect_to company_payroll_path(current_company), notice: "Payroll config updated" }
        format.json { render json: { payroll_config: format_config(config) } }
      end
    else
      respond_to do |format|
        format.html { redirect_to company_payroll_path(current_company), alert: config.errors.full_messages.to_sentence }
        format.json { render json: { errors: config.errors.full_messages }, status: :unprocessable_content }
      end
    end
  end

  private

  def payroll_config_params
    params.require(:payroll_config).permit(
      :date_basis,
      :include_attendance_months,
      :include_attendance_days,
      excluded_lifecycle_statuses: [],
      excluded_workflow_statuses: [],
      business_types: [],
      branch_ids: [],
      employee_ids: []
    )
  end

  def format_config(config)
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
end
