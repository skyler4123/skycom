# frozen_string_literal: true

# Booking::CancelService — cancels a booking from the Booking console.
# The cancelled Event drops out of the console and no longer blocks the space.
# Stock holds are released through Events::AfterSaveService.
# Docs: docs/OPERATIONS.md §7
class Booking::CancelService
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
      event.update!(workflow_status: :cancelled)
      Events::AfterSaveService.call(
        event: event,
        previous_workflow_status: previous_status,
        previous_stock_map: previous_stock_map
      )
    end

    { success: true, message: "Booking cancelled. The space can be booked again.", event: event.reload }
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

  def stock_map(event)
    event.event_stock_appointments.each_with_object({}) do |line, map|
      map[line.stock_id] = line.quantity.to_i
    end
  end

  def failure(errors)
    { success: false, errors: Array(errors) }
  end
end
