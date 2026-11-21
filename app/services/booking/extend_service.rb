# frozen_string_literal: true

# Booking::ExtendService — the Booking console's "+30 minutes" action.
# The event and every facility it uses are locked before the overlap check so
# a concurrent console reservation cannot slip in between the check and save.
# Docs: docs/OPERATIONS.md §7
class Booking::ExtendService
  EXTEND_MINUTES = 30

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
    return failure([ "This booking has no end time." ]) if event.end_at.blank?

    new_end = nil
    conflict = nil

    ActiveRecord::Base.transaction do
      event.lock!
      new_end = event.end_at + EXTEND_MINUTES.minutes
      facilities = event.facilities.order(:id).to_a
      facilities.each(&:lock!)

      facilities.each do |facility|
        found = Booking::ConflictChecker.call(
          company: company,
          facility: facility,
          start_at: event.start_at,
          end_at: new_end,
          exclude_event_id: event.id
        )
        next unless found

        conflict = found
        break
      end

      next if conflict

      event.update!(end_at: new_end)
    end

    return failure([ "Next booking starts at #{clock(conflict.start_at)}." ]) if conflict

    { success: true, message: "Booking extended by #{EXTEND_MINUTES} minutes.", event: event.reload }
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

  def clock(value)
    LocalTime.now(branch, at: value).strftime("%-I:%M %p")
  end

  def failure(errors)
    { success: false, errors: Array(errors) }
  end
end
