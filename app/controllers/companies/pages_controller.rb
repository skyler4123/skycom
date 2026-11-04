# frozen_string_literal: true

# Companies::PagesController — operating-page appointments (Shell-First).
# Index lists every branch and warehouse appointment for the company; launch
# resolves the appointment and redirects to the purpose-specific operation page.
# Serves Stimulus: Companies_Pages_IndexController (index, launch)
# Endpoints: GET /companies/:company_id/pages, GET /companies/:company_id/pages/:id/launch
# Docs: docs/OPERATING_PAGES.md
class Companies::PagesController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          page_appointments: format_appointments(page_appointments),
          roles: current_company.roles.order(:name).map { |role| { id: role.id, name: role.name } }
        }
      end
    end
  end

  def launch
    page = current_company.pages.find(params[:id])
    appointment = Pages::AppointmentResolver.call(
      company: current_company,
      page: page,
      employee: current_employee,
      branch_id: params[:branch_id],
      warehouse_id: params[:warehouse_id]
    )

    return render_launch_error("No active page appointment found for this location.") unless appointment
    return render_launch_error("This page appointment is inactive.") unless appointment.workflow_status_active?
    return render_launch_error("You do not have access to this page.", status: :forbidden) unless page.accessible_by?(current_employee)

    launch_path = PageLaunchService.call(
      company: current_company,
      page: page,
      appointment: appointment
    )

    respond_to do |format|
      format.html { redirect_to launch_path }
      format.json { render json: { launch_path: launch_path } }
    end
  end

  private

  def page_appointments
    branch_appointments = current_company.branch_page_appointments.includes(:page, :branch).to_a
    warehouse_appointments = current_company.page_warehouse_appointments.includes(:page, :warehouse).to_a

    (branch_appointments + warehouse_appointments).sort_by do |appointment|
      [
        appointment.page.name.to_s.downcase,
        appointment.is_a?(BranchPageAppointment) ? 0 : 1,
        PageSerializer.location(appointment)[:name].to_s.downcase
      ]
    end
  end

  def format_appointments(appointments)
    appointments.map do |appointment|
      PageSerializer.appointment(
        appointment,
        employee: current_employee,
        launch_path: launch_path_for(appointment)
      )
    end
  end

  def launch_path_for(appointment)
    if appointment.is_a?(BranchPageAppointment)
      launch_company_page_path(current_company, appointment.page, branch_id: appointment.branch_id)
    else
      launch_company_page_path(current_company, appointment.page, warehouse_id: appointment.warehouse_id)
    end
  end

  def render_launch_error(message, status: :unprocessable_content)
    respond_to do |format|
      format.html do
        redirect_to company_pages_path(current_company), alert: message
      end
      format.json { render json: { errors: [ message ] }, status: status }
    end
  end
end
