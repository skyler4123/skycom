# frozen_string_literal: true

# Reception::AdvanceService — moves a reception visit through its physical
# states while keeping the Event workflow status as the source of truth:
#
#   confirmed (waiting in lobby) → in_progress (inside) → completed (departed)
#   completed → confirmed (re-open at reception)
#
# The console renders those states as Lobby / Inside / Departed.
# Docs: docs/OPERATIONS.md, docs/EVENTS.md
class Reception::AdvanceService
  ACTIONS = {
    "check_in" => { from: %w[confirmed], to: :in_progress, message: "checked in and is now inside the building" },
    "check_out" => { from: %w[confirmed in_progress], to: :completed, message: "checked out. Access privileges revoked" },
    "reopen" => { from: %w[completed], to: :confirmed, message: "was re-opened in the lobby queue" }
  }.freeze

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
    event = company.events.find_by(id: params[:event_id], branch_id: appointment.branch_id)
    return failure([ "Visit not found." ]) unless event
    return failure([ "This is not a reception visit." ]) if event.metadata&.dig("reception_kind") == "parcel"

    action = params[:transition].to_s
    transition = ACTIONS[action]
    return failure([ "Unknown reception action." ]) unless transition
    return failure([ "This visit cannot be updated from its current state." ]) unless transition[:from].include?(event.workflow_status)

    metadata = (event.metadata || {}).dup
    metadata["checked_in_at"] = now.iso8601 if action == "check_in"
    metadata["checked_out_at"] = now.iso8601 if action == "check_out"
    metadata.delete("checked_out_at") if action == "reopen"

    event.update!(workflow_status: transition[:to], metadata: metadata)

    {
      success: true,
      event: event,
      message: "#{visit_name(event)} #{transition[:message]}."
    }
  rescue ActiveRecord::RecordInvalid => e
    failure(e.record.errors.full_messages.presence || [ e.message ])
  end

  private

  attr_reader :company, :appointment, :params, :now

  def visit_name(event)
    event.customer_event_appointments.first&.customer&.name.presence || event.name
  end

  def failure(errors)
    { success: false, errors: Array(errors) }
  end
end
