# frozen_string_literal: true

# Companies::PageWarehouseAppointmentsController — warehouse-level page toggles
# and metadata. Page config overrides this row's metadata when effective config
# is built. Only update is routed.
# Serves Stimulus: Companies_Pages_IndexController (edit config modal)
# Endpoints: PATCH /companies/:company_id/page_warehouse_appointments/:id
# Docs: docs/OPERATING_PAGES.md
class Companies::PageWarehouseAppointmentsController < Companies::ApplicationController
  def update
    appointment = current_company.page_warehouse_appointments
      .includes(:page, :warehouse)
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
    raw = params.require(:page_warehouse_appointment).permit!
    attrs = {}
    attrs[:workflow_status] = raw[:workflow_status] if raw.key?(:workflow_status)
    if raw.key?(:metadata)
      metadata = raw[:metadata]
      metadata = metadata.to_unsafe_h if metadata.respond_to?(:to_unsafe_h)
      attrs[:metadata] = metadata
    end
    attrs
  end

  def valid_workflow_status?
    raw = params.require(:page_warehouse_appointment)
    return true unless raw.key?(:workflow_status)

    PageWarehouseAppointment.workflow_statuses.key?(raw[:workflow_status].to_s)
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
