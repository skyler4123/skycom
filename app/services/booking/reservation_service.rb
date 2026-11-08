# frozen_string_literal: true

# Booking::ReservationService — creates a reservation Event from the booking
# console's Instant Reservation form.
#
# The reservation is persisted as a normal Event (category + property mapping)
# with the chosen Facility linked through EventFacilityAppointment. When the
# supplied host name matches a branch employee, an EmployeeEventAppointment is
# added as well.
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
    @date = date || Date.current
  end

  def call
    return failure([ "Meeting / event name is required." ]) if title.blank?
    return failure([ "Select a space for this reservation." ]) if facility.nil?
    return failure([ "Start time is invalid." ]) if start_at.nil?
    return failure([ "End time is invalid." ]) if end_at.nil?
    return failure([ "End time must be after start time." ]) if end_at <= start_at

    event = create_event!
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
    @facility ||= company.facilities
      .where("branch_id = ? OR branch_id IS NULL", branch.id)
      .find_by(id: params[:facility_id])
  end

  def category
    @category ||= Seed::CategoryService.find_or_create_for(company: company, resource_name: "events")
  end

  def start_at
    @start_at ||= parse_time(params[:start_time])
  end

  def end_at
    @end_at ||= parse_time(params[:end_time])
  end

  def parse_time(value)
    return nil if value.blank?

    Time.zone.parse("#{date.to_date} #{value}")
  rescue ArgumentError
    nil
  end

  def create_event!
    event = nil

    ActiveRecord::Base.transaction do
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
      employee = matching_employee
      EmployeeEventAppointment.create!(company: company, event: event, employee: employee) if employee
    end

    event
  end

  def matching_employee
    name = params[:host].to_s.strip
    return nil if name.blank?

    company.employees
      .where("branch_id = ? OR branch_id IS NULL", branch.id)
      .find_by(name: name)
  end

  def failure(errors)
    { success: false, errors: errors }
  end
end
