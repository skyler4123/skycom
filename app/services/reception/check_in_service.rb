# frozen_string_literal: true

# Reception::CheckInService — registers a walk-in visitor as a real Customer +
# Event, linked through the atomic appointment rows:
#
#   Customer  ← customer_event_appointments  → Event
#   Employee  ← employee_event_appointments  → Event
#   Facility  ← event_facility_appointments  → Event
#
# The Event starts `confirmed` (arrived, waiting in the lobby) so the reception
# console can move it to `in_progress` and `completed` through
# Reception::AdvanceService.
# Docs: docs/OPERATIONS.md, docs/EVENTS.md
class Reception::CheckInService
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

    return failure([ "Guest name is required." ]) if name.blank?
    return failure([ "Company or organization is required." ]) if visitor_company.blank?

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
        name: "Walk-in · #{name} · #{code}",
        code: code,
        business_type: :appointment,
        workflow_status: :confirmed,
        category: event_category,
        branch: appointment.branch,
        start_at: now,
        end_at: now + 2.hours,
        metadata: {
          "reception_kind" => "visit",
          "visitor_kind" => "Walk-in",
          "visitor_company" => visitor_company,
          "vip" => boolean(params[:vip]),
          "lobby_entered_at" => now.iso8601
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
      message: "Walk-in check-in complete for #{name}."
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

  def boolean(value)
    ActiveModel::Type::Boolean.new.cast(value) || false
  end

  def failure(errors)
    { success: false, errors: Array(errors) }
  end
end
