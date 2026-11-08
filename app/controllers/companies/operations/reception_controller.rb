# frozen_string_literal: true

# Companies::Operations::ReceptionController — the Reception operation.
# Hydrates the resolved BranchOperationAppointment, then exposes the live
# console payload (today's visit Events, held parcels, facility rooms and next
# appointments) plus the write actions the front desk uses:
#
#   POST check_in      — walk-in Customer + Event (+ host / room links)
#   POST advance       — check in / check out / re-open a visit Event
#   POST create_parcel — persist a held parcel as an Event
#   POST notify_parcel — stamp the parcel's notified_at metadata
#   POST pick_up_parcel — complete the parcel Event
#   POST notify_host   — stamp the visit's host_notified_at metadata
#
# Serves Stimulus: Companies_Operations_Reception_ShowController (reception console)
# Endpoints: GET  /companies/:company_id/operations/reception/:operation_id
#            POST /companies/:company_id/operations/reception/:operation_id/check_in
#            POST /companies/:company_id/operations/reception/:operation_id/advance
#            POST /companies/:company_id/operations/reception/:operation_id/parcels
#            POST /companies/:company_id/operations/reception/:operation_id/parcels/:parcel_id/notify
#            POST /companies/:company_id/operations/reception/:operation_id/parcels/:parcel_id/pick_up
#            POST /companies/:company_id/operations/reception/:operation_id/notify_host
# Docs: docs/OPERATIONS.md, docs/EVENTS.md
class Companies::Operations::ReceptionController < Companies::Operations::BaseController
  def check_in
    result = Reception::CheckInService.call(
      company: current_company,
      appointment: @appointment,
      params: visitor_params
    )
    render_result(result, success_status: :created)
  end

  def advance
    result = Reception::AdvanceService.call(
      company: current_company,
      appointment: @appointment,
      params: { event_id: params[:event_id], transition: params[:transition] }
    )
    render_result(result)
  end

  def create_parcel
    result = Reception::ParcelService.create(
      company: current_company,
      appointment: @appointment,
      params: parcel_params
    )
    render_result(result, success_status: :created)
  end

  def notify_parcel
    result = Reception::ParcelService.notify(
      company: current_company,
      appointment: @appointment,
      parcel_id: params[:parcel_id]
    )
    render_result(result)
  end

  def pick_up_parcel
    result = Reception::ParcelService.pick_up(
      company: current_company,
      appointment: @appointment,
      parcel_id: params[:parcel_id]
    )
    render_result(result)
  end

  def notify_host
    event = current_company.events.find_by(id: params[:event_id], branch_id: @appointment.branch_id)
    return render json: { errors: [ "Visit not found." ] }, status: :not_found unless event
    return render json: { errors: [ "This is not a reception visit." ] }, status: :unprocessable_content if event.metadata&.dig("reception_kind") == "parcel"

    event.update!(metadata: (event.metadata || {}).merge("host_notified_at" => Time.current.iso8601))
    render json: { message: "Host notification logged for #{visit_name(event)}." }
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
  end

  private

  def expected_operation_type
    :reception
  end

  def operation_payload
    {
      coming_soon: false,
      reception: Reception::ConsoleService.call(company: current_company, appointment: @appointment),
      reference: reference_payload
    }
  end

  def reference_payload
    branch = @appointment.branch
    hosts = current_company.employees
      .where("branch_id = ? OR branch_id IS NULL", branch.id)
      .includes(:category)
      .order(:name)
      .limit(100)

    facilities = current_company.facilities
      .where("branch_id = ? OR branch_id IS NULL", branch.id)
      .includes(:category)
      .order(:name)
      .limit(100)

    {
      hosts: hosts.map do |employee|
        role = employee.category&.name
        role = "Host" if role.blank? || role == "Employees"
        { id: employee.id, name: employee.name, role: role }
      end,
      facilities: facilities.map do |facility|
        category = facility.category&.name
        category = nil if category == "Facilities"
        { id: facility.id, name: facility.name, category: category }
      end
    }
  end

  def visitor_params
    params.require(:visitor).permit(:name, :company, :host_id, :facility_id, :notify, :print)
  end

  def parcel_params
    params.require(:parcel).permit(:carrier, :item, :employee_id)
  end

  def render_result(result, success_status: :ok)
    if result[:success]
      render json: {
        message: result[:message],
        event: result[:event] && { id: result[:event].id }
      }, status: success_status
    else
      render json: { errors: result[:errors] }, status: :unprocessable_content
    end
  end

  def visit_name(event)
    event.customer_event_appointments.first&.customer&.name.presence || event.name
  end
end
