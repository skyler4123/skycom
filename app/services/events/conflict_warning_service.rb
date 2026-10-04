# frozen_string_literal: true

# Warns about double-booked facilities/hosts and short stock for an Event.
#
# Warn-but-allow contract (result-hash style): { warnings: [...] } — callers
# save the event regardless (unless the category's EventConfig asks for
# strict holds, which is handled by the hold flow, not here). Missing
# EventConfig, missing flags, or missing time window all mean silence.
module Events
  class ConflictWarningService
    def self.call(event:)
      new(event: event).call
    end

    def initialize(event:)
      @event = event
    end

    def call
      return { warnings: [] } unless checkable?

      { warnings: facility_warnings + host_warnings + stock_warnings }
    end

    private

    def checkable?
      @event.persisted? && @event.start_at.present? && @event.end_at.present?
    end

    def config
      @config ||= EventConfig.find_by(company_id: @event.company_id, category_id: @event.category_id)
    end

    def overlapping
      Event.where(company_id: @event.company_id)
        .where.not(id: @event.id)
        .where.not(workflow_status: :cancelled)
        .where("start_at < ? AND end_at > ?", @event.end_at, @event.start_at)
    end

    def facility_warnings
      return [] unless config&.warn_on_facility_overlap?
      return [] if @event.facility_ids.empty?

      clashes = overlapping.joins(:event_facility_appointments)
        .where(event_facility_appointments: { facility_id: @event.facility_ids })
      clashes.distinct.flat_map do |other|
        (other.facility_ids & @event.facility_ids).map do |facility_id|
          facility = Facility.find_by(id: facility_id)
          "Facility #{facility&.name || facility_id} is already booked by #{other.name} in this window"
        end
      end
    end

    def host_warnings
      return [] unless config&.warn_on_host_overlap?
      return [] if @event.employee_ids.empty?

      clashes = overlapping.joins(:employee_event_appointments)
        .where(employee_event_appointments: { employee_id: @event.employee_ids })
      clashes.distinct.flat_map do |other|
        (other.employee_ids & @event.employee_ids).map do |employee_id|
          employee = Employee.find_by(id: employee_id)
          "#{employee&.name || employee_id} already hosts #{other.name} in this window"
        end
      end
    end

    def stock_warnings
      @event.event_stock_appointments.filter_map do |line|
        stock = line.stock
        next if stock.available_count >= line.quantity.to_i

        "Stock #{stock.name} cannot cover this event (need #{line.quantity}, available #{stock.available_count})"
      end
    end
  end
end
