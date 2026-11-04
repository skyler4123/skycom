# frozen_string_literal: true

# Companies::BranchPageAppointmentsController — branch-level page toggles and
# metadata. Page config overrides this row's metadata when effective config is
# built. Only update is routed.
# Serves Stimulus: Companies_Pages_IndexController (edit config modal)
# Endpoints: PATCH /companies/:company_id/branch_page_appointments/:id
# Docs: docs/OPERATING_PAGES.md
class Companies::BranchPageAppointmentsController < Companies::ApplicationController
  def update
    appointment = current_company.branch_page_appointments
      .includes(:page, :branch)
      .find(params[:id])

    return render_invalid_status unless valid_workflow_status?

    if appointment.update(appointment_params)
      respond_to do |format|
        format.html { redirect_to company_pages_path(current_company), notice: "Page appointment updated." }
        format.json do
          render json: {
            appointment: PageSerializer.appointment(
              appointment,
              employee: current_employee,
              launch_path: launch_path_for(appointment)
            ),
            message: "Page appointment updated."
          }
        end
      end
    else
      render_errors(appointment.errors.full_messages)
    end
  end

  private

  def appointment_params
    params.require(:branch_page_appointment).permit(:workflow_status, metadata: {})
  end

  def valid_workflow_status?
    raw = params.require(:branch_page_appointment)
    return true unless raw.key?(:workflow_status)

    BranchPageAppointment.workflow_statuses.key?(raw[:workflow_status].to_s)
  end

  def launch_path_for(appointment)
    PageLaunchService.call(
      company: current_company,
      page: appointment.page,
      appointment: appointment
    )
  end

  def render_invalid_status
    render_errors([ "Invalid workflow status" ])
  end

  def render_errors(errors)
    respond_to do |format|
      format.html { redirect_to company_pages_path(current_company), alert: errors.to_sentence }
      format.json { render json: { errors: errors }, status: :unprocessable_content }
    end
  end
end
