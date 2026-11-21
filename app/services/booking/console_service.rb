# frozen_string_literal: true

# Booking::ConsoleService — builds the live booking console payload for a
# branch appointment:
#
# - resources: branch Facilities (real categories, never inferred from names)
# - bookings: the day's Events whose time touches the selected day, with the
#   organiser, customer, facility links, attendee count and a clock-derived
#   status
# - counts: KPI counts over the full day/branch scope, even when the visible
#   lists are capped
# - upcoming: the next five not-yet-started bookings
# - caps: explicit cap flags and limits for the UI
#
# Why Events + Facilities: a booking is an Event and the reserved space is a
# Facility linked through EventFacilityAppointment. This reuses the existing
# domain instead of adding a separate reservation table.
# Docs: docs/OPERATIONS.md, docs/EVENTS.md
class Booking::ConsoleService
  TIMELINE_START_HOUR = 8
  TIMELINE_END_HOUR = 18
  UPCOMING_LIMIT = 5

  def self.call(company:, appointment:, now: Time.current, date: nil)
    new(company: company, appointment: appointment, now: now, date: date).call
  end

  def initialize(company:, appointment:, now:, date:)
    @company = company
    @appointment = appointment
    @branch = appointment.branch
    @now = now
    @date = date || LocalTime.today(@branch, at: now)
  end

  def call
    {
      date: date.iso8601,
      now: now.utc.iso8601,
      timeline: { start_hour: TIMELINE_START_HOUR, end_hour: TIMELINE_END_HOUR },
      resources: resources,
      bookings: bookings,
      upcoming: upcoming,
      counts: counts,
      caps: caps
    }
  end

  private

  attr_reader :company, :appointment, :branch, :now, :date

  def facilities_scope
    @facilities_scope ||= company.facilities
      .where("branch_id = ? OR branch_id IS NULL", branch.id)
      .includes(:category)
      .order(:name)
  end

  def facilities
    return @facilities if defined?(@facilities)

    records = facilities_scope.limit(BOOKING_FACILITY_LIMIT + 1).to_a
    @resources_capped = records.length > BOOKING_FACILITY_LIMIT
    @facilities = records.first(BOOKING_FACILITY_LIMIT)
  end

  def events_scope
    @events_scope ||= begin
      day_range = LocalTime.day_range(date, branch)

      company.events
        .where(branch_id: branch.id)
        .where.not(start_at: nil)
        .where.not(end_at: nil)
        .where("start_at < :end AND end_at > :start", start: day_range.begin, end: day_range.end)
        .where.not(workflow_status: :cancelled)
    end
  end

  def events
    return @events if defined?(@events)

    records = events_scope
      .includes(
        :category,
        customer_event_appointments: :customer,
        employee_event_appointments: :employee,
        event_facility_appointments: :facility
      )
      .order(:start_at)
      .limit(BOOKING_DAY_BOOKING_LIMIT + 1)
      .to_a

    @bookings_capped = records.length > BOOKING_DAY_BOOKING_LIMIT
    @events = records.first(BOOKING_DAY_BOOKING_LIMIT)
  end

  def bookings
    @bookings ||= events.map { |event| booking_payload(event) }
  end

  def resources
    @resources ||= facilities.map { |facility| resource_payload(facility) }
  end

  def resource_payload(facility)
    {
      id: facility.id,
      name: facility.name,
      code: facility.code,
      category: category_name(facility),
      capacity: facility.property_integer_1,
      in_use: busy_facility_ids.include?(facility.id)
    }
  end

  def booking_payload(event)
    facilities = event.event_facility_appointments.map(&:facility)
    host = event.employee_event_appointments.first&.employee
    customer = event.customer_event_appointments.first&.customer

    {
      id: event.id,
      title: event.name,
      code: event.code,
      start_at: event.start_at&.iso8601,
      end_at: event.end_at&.iso8601,
      status: Booking::Status.for(event, now: now),
      resource_ids: facilities.map(&:id),
      facilities: facilities.map do |facility|
        {
          id: facility.id,
          name: facility.name,
          category: category_name(facility),
          capacity: facility.property_integer_1
        }
      end,
      host: host ? { id: host.id, name: host.name } : nil,
      customer: customer ? { id: customer.id, name: customer.name } : nil,
      attendees: event.customer_event_appointments.length + event.employee_event_appointments.length
    }
  end

  def upcoming
    @upcoming ||= bookings
      .select { |booking| booking[:status] == "upcoming" }
      .sort_by { |booking| booking[:start_at] }
      .first(UPCOMING_LIMIT)
      .map do |booking|
        booking.merge(
          facility_name: booking[:facilities].map { |facility| facility[:name] }.join(", ").presence
        )
      end
  end

  def counts
    @counts ||= begin
      statuses = events_scope.select(:workflow_status, :start_at, :end_at).map do |event|
        Booking::Status.for(event, now: now)
      end
      totals = category_totals.sort_by { |name, _| name.to_s }.to_h
      in_use = category_in_use_counts
      spaces_total = totals.values.sum
      spaces_in_use = facilities_scope.where(id: busy_facility_ids).count

      {
        total_bookings: statuses.length,
        upcoming: statuses.count("upcoming"),
        in_progress: statuses.count("in_progress"),
        done: statuses.count("done"),
        spaces_total: spaces_total,
        spaces_in_use: spaces_in_use,
        utilization: spaces_total.zero? ? 0 : ((spaces_in_use.to_f / spaces_total) * 100).round,
        categories: totals.map do |name, total|
          used = in_use[name] || 0
          { name: name, total: total, in_use: used, free: total - used }
        end
      }
    end
  end

  def caps
    {
      bookings: { capped: @bookings_capped || false, limit: BOOKING_DAY_BOOKING_LIMIT },
      resources: { capped: @resources_capped || false, limit: BOOKING_FACILITY_LIMIT }
    }
  end

  def category_totals
    facilities_scope.reorder(nil).joins(:category).group("categories.name").count
  end

  def category_in_use_counts
    return {} if busy_facility_ids.empty?

    facilities_scope
      .reorder(nil)
      .where(id: busy_facility_ids)
      .joins(:category)
      .group("categories.name")
      .count
  end

  def busy_facility_ids
    @busy_facility_ids ||= begin
      ids = events_scope
        .where("events.end_at > ?", now)
        .where.not(workflow_status: :completed)
        .where(
          "events.workflow_status = :in_progress OR (events.start_at <= :now AND events.end_at > :now)",
          in_progress: Event.workflow_statuses[:in_progress], now: now
        )
        .select(:id)

      EventFacilityAppointment
        .where(company_id: company.id, event_id: ids)
        .distinct
        .pluck(:facility_id)
    end
  end

  def category_name(facility)
    facility.category&.name.presence || "Other spaces"
  end
end
