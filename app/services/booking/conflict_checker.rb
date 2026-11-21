# frozen_string_literal: true

# Booking::ConflictChecker — the one overlap query behind the Booking console.
# A console booking may not share a minute with another active booking of the
# same facility. Back-to-back windows are allowed because both comparisons are
# strict. Cancelled and completed bookings have released the space.
#
# This is deliberately stricter than the Events module's warn-but-allow
# contract; see docs/EVENTS.md.
# Docs: docs/OPERATIONS.md §7
module Booking
  class ConflictChecker
    def self.call(company:, facility:, start_at:, end_at:, exclude_event_id: nil)
      new(company: company, facility: facility, start_at: start_at,
        end_at: end_at, exclude_event_id: exclude_event_id).call
    end

    def initialize(company:, facility:, start_at:, end_at:, exclude_event_id: nil)
      @company = company
      @facility = facility
      @start_at = start_at
      @end_at = end_at
      @exclude_event_id = exclude_event_id
    end

    def call
      return nil if start_at.blank? || end_at.blank?

      scope = company.events
        .joins(:event_facility_appointments)
        .where(event_facility_appointments: { facility_id: facility.id })
        .where.not(workflow_status: [ :cancelled, :completed ])
        .where.not(start_at: nil)
        .where.not(end_at: nil)
        .where("events.start_at < ? AND events.end_at > ?", end_at, start_at)
        .order(:start_at)

      scope = scope.where.not(id: exclude_event_id) if exclude_event_id.present?
      scope.first
    end

    private

    attr_reader :company, :facility, :start_at, :end_at, :exclude_event_id
  end
end
