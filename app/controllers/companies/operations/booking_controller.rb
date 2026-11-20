# frozen_string_literal: true

# Companies::Operations::BookingController — the Booking operation.
# Hydrates the resolved BranchOperationAppointment, then exposes the live
# booking console payload (the day's facility reservations, timeline resources,
# KPI counts, next check-ins, caps) plus the reference lists and lookup used by
# the reservation form.
#
#   GET  /companies/:company_id/operations/booking/:operation_id
#   GET  /companies/:company_id/operations/booking/:operation_id/customers
#   POST /companies/:company_id/operations/booking/:operation_id/reservations
#   POST /companies/:company_id/operations/booking/:operation_id/reservations/:reservation_id/extend
#   POST /companies/:company_id/operations/booking/:operation_id/reservations/:reservation_id/end
#   POST /companies/:company_id/operations/booking/:operation_id/reservations/:reservation_id/cancel
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

    render_result(result, status: :created)
  end

  def customers
    render json: {
      customers: Booking::CustomerSearchService.call(company: current_company, query: params[:q])
    }
  end

  def extend_reservation
    render_result Booking::ExtendService.call(
      company: current_company,
      appointment: @appointment,
      event_id: params[:reservation_id],
      now: Time.current
    )
  end

  def finish_reservation
    render_result Booking::FinishService.call(
      company: current_company,
      appointment: @appointment,
      event_id: params[:reservation_id],
      now: Time.current
    )
  end

  def cancel_reservation
    render_result Booking::CancelService.call(
      company: current_company,
      appointment: @appointment,
      event_id: params[:reservation_id],
      now: Time.current
    )
  end

  private

  def expected_operation_type
    :booking
  end

  def operation_payload
    {
      coming_soon: false,
      company: { id: current_company.id, name: current_company.name },
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
    params.require(:booking).permit(:title, :facility_id, :host_id, :customer_id, :start_time, :end_time, :date)
  end

  def render_result(result, status: :ok)
    if result[:success]
      render json: {
        message: result[:message],
        event: { id: result[:event].id }
      }, status: status
    else
      render json: { errors: result[:errors] }, status: :unprocessable_content
    end
  end

  def reference_payload
    branch = @appointment.branch

    hosts = current_company.employees
      .where("branch_id = ? OR branch_id IS NULL", branch.id)
      .includes(:category)
      .order(:name)
      .limit(BOOKING_HOST_LIMIT + 1)
      .to_a

    facilities = current_company.facilities
      .where("branch_id = ? OR branch_id IS NULL", branch.id)
      .includes(:category)
      .order(:name)
      .limit(BOOKING_FACILITY_LIMIT + 1)
      .to_a

    {
      hosts: hosts.first(BOOKING_HOST_LIMIT).map do |employee|
        { id: employee.id, name: employee.name, role: employee.category&.name }
      end,
      facilities: facilities.first(BOOKING_FACILITY_LIMIT).map do |facility|
        {
          id: facility.id,
          name: facility.name,
          category: facility.category&.name.presence || "Other spaces",
          capacity: facility.property_integer_1
        }
      end,
      caps: {
        hosts: { capped: hosts.length > BOOKING_HOST_LIMIT, limit: BOOKING_HOST_LIMIT },
        facilities: { capped: facilities.length > BOOKING_FACILITY_LIMIT, limit: BOOKING_FACILITY_LIMIT }
      }
    }
  end
end
