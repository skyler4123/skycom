# frozen_string_literal: true

# Reception::NotifyHostService — sends one direct in-app notification to the
# host of an expected or lobby visit and records `host_notified_at`.
#
# Repeated clicks create another notification each time; this is intentional
# (the receptionist may need to nudge the host again).
# Docs: docs/OPERATIONS.md, docs/EVENTS.md
class Reception::NotifyHostService
  def self.call(company:, appointment:, event_id:, now: Time.current)
    new(company: company, appointment: appointment, event_id: event_id, now: now).call
  end

  def initialize(company:, appointment:, event_id:, now:)
    @company = company
    @appointment = appointment
    @event_id = event_id
    @now = now
  end

  def call
    event = company.events.find_by(id: event_id, branch_id: appointment.branch_id)
    return failure([ "Visit not found." ]) unless event
    return failure([ "This is not a reception visit." ]) unless reception_visit?(event)

    host = event.employee_event_appointments.includes(:employee).first&.employee
    return failure([ "No host to notify." ]) unless host

    guest_name = event.customer_event_appointments.first&.customer&.name.presence || event.name
    notification_result = nil

    ActiveRecord::Base.transaction do
      notification_result = Notifications::CreateService.call(
        company: company,
        name: notification_name(event, guest_name),
        description: notification_description(event, guest_name),
        severity: :info,
        recipient_employee: host
      )
      raise ActiveRecord::Rollback unless notification_result[:success]

      event.update!(
        metadata: (event.metadata || {}).merge("host_notified_at" => now.iso8601)
      )
    end

    return failure(notification_result[:errors]) unless notification_result[:success]

    {
      success: true,
      event: event,
      notification: notification_result[:notification],
      message: "Host notified for #{guest_name}."
    }
  rescue ActiveRecord::RecordInvalid => e
    failure(e.record.errors.full_messages.presence || [ e.message ])
  end

  private

  attr_reader :company, :appointment, :event_id, :now

  def reception_visit?(event)
    event.metadata&.dig("reception_kind") == "visit" &&
      event.customer_event_appointments.exists?
  end

  def notification_name(event, guest_name)
    event.workflow_status_pending? || event.workflow_status_draft? ? "Guest expected: #{guest_name}" : "Guest arrived: #{guest_name}"
  end

  def notification_description(event, guest_name)
    room = event.event_facility_appointments.first&.facility&.name
    visitor_company = event.metadata&.dig("visitor_company")
    details = [ visitor_company, room ].compact_blank.join(" · ")
    details = " at #{details}" if details.present?
    if event.workflow_status_pending? || event.workflow_status_draft?
      "#{guest_name} is expected at #{appointment.branch.name} reception#{details}."
    else
      "#{guest_name} has arrived at #{appointment.branch.name} reception#{details}."
    end
  end

  def failure(errors)
    { success: false, errors: Array(errors) }
  end
end
