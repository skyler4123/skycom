# frozen_string_literal: true

# Booking::ReservationService — creates a reservation Event from the booking
# console's Instant reservation form.
#
# The reservation is persisted as a normal Event (category + property mapping)
# with the chosen Facility linked through EventFacilityAppointment. Host and
# customer are optional real records linked through their event appointments.
#
# The facility row is locked before the overlap check and creation so two
# console hosts cannot both pass the check for the same space/time.
# Docs: docs/OPERATIONS.md, docs/EVENTS.md
class Booking::ReservationService
  def self.call(company:, appointment:, params:, date: nil)
    new(company: company, appointment: appointment, params: params, date: date).call
  end

  def initialize(company:, appointment:, params:, date:)
    @company = company
    @appointment = appointment
    @branch = appointment.branch
    @params = params
    @date = date || LocalTime.today(@branch)
  end

  def call
    return failure([ "Meeting / event name is required." ]) if title.blank?
    return failure([ "Select a space for this reservation." ]) if facility.nil?
    return failure([ "Start time is invalid." ]) if start_at.nil?
    return failure([ "End time is invalid." ]) if end_at.nil?
    return failure([ "End time must be after start time." ]) if end_at <= start_at
    return failure([ "Host not found." ]) if host_id.present? && host.nil?
    return failure([ "Customer not found." ]) if customer_id.present? && customer.nil?

    conflict = nil
    event = nil

    ActiveRecord::Base.transaction do
      facility.lock!
      conflict = Booking::ConflictChecker.call(
        company: company, facility: facility, start_at: start_at, end_at: end_at
      )
      next if conflict

      event = create_event!
    end

    return failure([ conflict_message(conflict) ]) if conflict

    { success: true, message: "Reservation confirmed for #{event.name}.", event: event }
  rescue ActiveRecord::RecordInvalid => e
    failure(e.record.errors.full_messages)
  rescue ArgumentError, TypeError
    failure([ "The reservation time could not be parsed." ])
  end

  private

  attr_reader :company, :appointment, :branch, :params, :date

  def title
    params[:title].to_s.strip
  end

  def facility
    return @facility if defined?(@facility)

    @facility = company.facilities
      .where("branch_id = ? OR branch_id IS NULL", branch.id)
      .find_by(id: params[:facility_id])
  end

  def host_id
    params[:host_id].presence
  end

  def host
    return @host if defined?(@host)

    @host = host_id && company.employees
      .where("branch_id = ? OR branch_id IS NULL", branch.id)
      .find_by(id: host_id)
  end

  def customer_id
    params[:customer_id].presence
  end

  def customer
    return @customer if defined?(@customer)

    @customer = customer_id && company.customers.find_by(id: customer_id)
  end

  def category
    @category ||= Seed::CategoryService.find_or_create_for(company: company, resource_name: "events")
  end

  def start_at
    return @start_at if defined?(@start_at)

    @start_at = parse_time(params[:start_time])
  end

  def end_at
    return @end_at if defined?(@end_at)

    @end_at = parse_time(params[:end_time])
  end

  def parse_time(value)
    return nil if value.blank?

    LocalTime.parse(date, value, branch)
  end

  def create_event!
    event = company.events.create!(
      name: title,
      branch: branch,
      category: category,
      property_mapping: category.default_property_mapping,
      start_at: start_at,
      end_at: end_at,
      workflow_status: :confirmed,
      business_type: :reservation,
      code: "BKG-#{SecureRandom.hex(4).upcase}",
      metadata: { "booking_source" => "booking_console" }
    )

    EventFacilityAppointment.create!(company: company, event: event, facility: facility)
    EmployeeEventAppointment.create!(company: company, event: event, employee: host) if host
    CustomerEventAppointment.create!(company: company, event: event, customer: customer) if customer
    event
  end

  def conflict_message(conflict)
    "#{facility.name} is already booked #{clock(conflict.start_at)}–#{clock(conflict.end_at)}."
  end

  def clock(value)
    LocalTime.now(branch, at: value).strftime("%-I:%M %p")
  end

  def failure(errors)
    { success: false, errors: Array(errors) }
  end
end
