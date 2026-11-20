# frozen_string_literal: true

# Booking::FinishService — the Booking console's "End & release" action.
# An in-progress booking ends now; an upcoming booking is simply closed and
# leaves the future timeline. Stock holds are released through the sanctioned
# Events::AfterSaveService path.
# Docs: docs/OPERATIONS.md §7
class Booking::FinishService
  def self.call(company:, appointment:, event_id:, now: Time.current)
    new(company: company, appointment: appointment, event_id: event_id, now: now).call
  end

  def initialize(company:, appointment:, event_id:, now:)
    @company = company
    @appointment = appointment
    @branch = appointment.branch
    @event_id = event_id
    @now = now
  end

  def call
    event = find_event
    return failure([ "Booking not found." ]) unless event
    return failure([ "This booking is already closed." ]) if closed?(event)

    ActiveRecord::Base.transaction do
      event.lock!
      previous_status = event.workflow_status
      previous_stock_map = stock_map(event)
      attributes = { workflow_status: :completed }
      attributes[:end_at] = now if in_progress?(event)
      event.update!(attributes)
      Events::AfterSaveService.call(
        event: event,
        previous_workflow_status: previous_status,
        previous_stock_map: previous_stock_map
      )
    end

    { success: true, message: "Booking ended. The space is free.", event: event.reload }
  rescue ActiveRecord::RecordInvalid => e
    failure(e.record.errors.full_messages)
  end

  private

  attr_reader :company, :appointment, :branch, :event_id, :now

  def find_event
    company.events.find_by(id: event_id, branch_id: branch.id)
  end

  def closed?(event)
    %w[done cancelled].include?(Booking::Status.for(event, now: now))
  end

  def in_progress?(event)
    event.start_at.present? && event.start_at <= now &&
      event.end_at.present? && event.end_at > now
  end

  def stock_map(event)
    event.event_stock_appointments.each_with_object({}) do |line, map|
      map[line.stock_id] = line.quantity.to_i
    end
  end

  def failure(errors)
    { success: false, errors: Array(errors) }
  end
end
