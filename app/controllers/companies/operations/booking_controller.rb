# frozen_string_literal: true

# Companies::Operations::BookingController — the Booking operation.
# Hydrates the resolved BranchOperationAppointment, then exposes the live
# booking console payload (the day's facility reservations, timeline resources,
# KPI counts and next check-ins) plus the reference lists used by the
# reservation form.
#
#   GET  /companies/:company_id/operations/booking/:operation_id
#   POST /companies/:company_id/operations/booking/:operation_id/reservations
#
# Serves Stimulus: Companies_Operations_Booking_ShowController (booking console)
# Docs: docs/OPERATIONS.md, docs/EVENTS.md
class Companies::Operations::BookingController < Companies::Operations::BaseController
  def create_reservation
    result = Booking::ReservationService.call(
      company: current_company,
      appointment: @appointment,
      params: reservation_params,
      date: requested_date
    )

    if result[:success]
      render json: {
        message: result[:message],
        event: { id: result[:event].id }
      }, status: :created
    else
      render json: { errors: result[:errors] }, status: :unprocessable_content
    end
  end

  private

  def expected_operation_type
    :booking
  end

  def operation_payload
    {
      coming_soon: false,
      booking: Booking::ConsoleService.call(
        company: current_company,
        appointment: @appointment,
        now: Time.current,
        date: requested_date
      ),
      reference: reference_payload
    }
  end

  def requested_date
    value = params[:date].presence || params.dig(:booking, :date).presence
    Date.parse(value) if value.present?
  rescue ArgumentError, TypeError
    nil
  end

  def reservation_params
    params.require(:booking).permit(:title, :facility_id, :host, :start_time, :end_time, :date)
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
        {
          id: facility.id,
          name: facility.name,
          category: category,
          capacity: facility.property_integer_1
        }
      end
    }
  end
end
