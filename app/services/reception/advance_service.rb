# frozen_string_literal: true

# Reception::AdvanceService — moves a reception visit through its physical
# states while keeping the Event workflow status as the source of truth:
#
#   pending/draft (expected) → confirmed (lobby) → in_progress (inside)
#   in_progress → completed (departed)
#   completed → in_progress (re-open inside)
#
# The console renders those states as Expected / Lobby / Inside / Departed.
# Docs: docs/OPERATIONS.md, docs/EVENTS.md
class Reception::AdvanceService
  ACTIONS = {
    "arrive" => {
      from: %w[pending draft],
      to: :confirmed,
      stamp: "lobby_entered_at",
      message: "has arrived and is waiting in the lobby"
    },
    "mark_inside" => {
      from: %w[confirmed],
      to: :in_progress,
      stamp: "inside_at",
      message: "is now inside the building"
    },
    "check_out" => {
      from: %w[in_progress],
      to: :completed,
      stamp: "checked_out_at",
      message: "has checked out"
    },
    "reopen" => {
      from: %w[completed],
      to: :in_progress,
      stamp: "inside_at",
      message: "was re-opened inside the building"
    }
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
    return failure([ "This is not a reception visit." ]) unless reception_visit?(event)

    transition = ACTIONS[params[:transition].to_s]
    return failure([ "Unknown reception action." ]) unless transition
    return failure([ "This visit cannot be updated from its current state." ]) unless transition[:from].include?(event.workflow_status)

    metadata = (event.metadata || {}).dup
    metadata[transition[:stamp]] = now.iso8601
    metadata.delete("checked_out_at") if params[:transition].to_s == "reopen"

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

  def reception_visit?(event)
    event.metadata&.dig("reception_kind") == "visit" &&
      event.customer_event_appointments.exists?
  end

  def visit_name(event)
    event.customer_event_appointments.first&.customer&.name.presence || event.name
  end

  def failure(errors)
    { success: false, errors: Array(errors) }
  end
end
