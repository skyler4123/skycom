# frozen_string_literal: true

# Reception::PreRegisterService — saves an expected visitor as a `pending` visit
# Event. The receptionist never leaves the Reception page to open Events.
#
# Date and time are wall-clock values in the branch timezone; the Event stores
# UTC. Room overlap is deliberately allowed here — this page does not lock rooms
# or perform booking conflict checks.
# Docs: docs/OPERATIONS.md, docs/EVENTS.md
class Reception::PreRegisterService
  def self.call(company:, appointment:, params:, now: Time.current)
    new(company: company, appointment: appointment, params: params, now: now).call
  end

  def initialize(company:, appointment:, params:, now:)
    @company = company
    @appointment = appointment
    @params = params
    @now = now
  end

  def call
    name = params[:name].to_s.strip
    visitor_company = params[:company].to_s.strip
    date = params[:date].to_s.strip
    start_time = params[:start_time].to_s.strip
    end_time = params[:end_time].to_s.strip

    return failure([ "Guest name is required." ]) if name.blank?
    return failure([ "Company or organization is required." ]) if visitor_company.blank?
    return failure([ "Date is required." ]) if date.blank?
    return failure([ "Start time is required." ]) if start_time.blank?

    start_at = LocalTime.parse(date, start_time, appointment.branch)
    return failure([ "Start date and time are invalid." ]) unless start_at

    end_at = if end_time.present?
      LocalTime.parse(date, end_time, appointment.branch)
    else
      start_at + 1.hour
    end
    return failure([ "End time is invalid." ]) unless end_at
    return failure([ "End time must be after start time." ]) unless end_at > start_at

    host = company.employees
      .where("branch_id = ? OR branch_id IS NULL", appointment.branch_id)
      .find_by(id: params[:host_id])
    facility = company.facilities
      .where("branch_id = ? OR branch_id IS NULL", appointment.branch_id)
      .find_by(id: params[:facility_id]) if params[:facility_id].present?
    customer = nil
    event = nil

    ActiveRecord::Base.transaction do
      customer = Reception::GuestResolver.call(
        company: company,
        branch: appointment.branch,
        name: name,
        visitor_company: visitor_company
      )
      code = "VIS-#{SecureRandom.hex(3).upcase}"
      event = company.events.create!(
        name: "Pre-registration · #{name} · #{code}",
        code: code,
        business_type: :appointment,
        workflow_status: :pending,
        category: event_category,
        branch: appointment.branch,
        start_at: start_at,
        end_at: end_at,
        metadata: {
          "reception_kind" => "visit",
          "visitor_kind" => "Pre-registered",
          "visitor_company" => visitor_company,
          "vip" => boolean(params[:vip]),
          "pre_registered_at" => now.iso8601
        }
      )
      CustomerEventAppointment.create!(company: company, event: event, customer: customer)
      EmployeeEventAppointment.create!(company: company, event: event, employee: host) if host
      EventFacilityAppointment.create!(company: company, event: event, facility: facility) if facility
    end

    {
      success: true,
      event: event.reload,
      customer: customer,
      message: "Pre-registration saved for #{name} on #{start_label(start_at)}."
    }
  rescue ActiveRecord::RecordInvalid => e
    failure(e.record.errors.full_messages.presence || [ e.message ])
  end

  private

  attr_reader :company, :appointment, :params, :now

  def event_category
    @event_category ||= Category.find_or_create_by!(
      company: company,
      resource_name: "events",
      name: "Reception"
    )
  end

  def start_label(start_at)
    LocalTime.now(appointment.branch, at: start_at).strftime("%-d %b %Y, %-I:%M %p")
  end

  def boolean(value)
    ActiveModel::Type::Boolean.new.cast(value) || false
  end

  def failure(errors)
    { success: false, errors: Array(errors) }
  end
end
