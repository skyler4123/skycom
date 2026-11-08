# frozen_string_literal: true

# Booking::ConsoleService — builds the live booking console payload for a
# branch appointment:
#
# - resources: branch Facilities (rooms, pods, studios, equipment) that act as
#   the timeline rows
# - bookings: the day's Events linked to those Facilities, together with the
#   organiser, attendee count and a time-derived status
# - upcoming: the next bookings used by the check-in queue
# - counts: the KPI strip values (bookings, utilisation, equipment, desks)
#
# Why Events + Facilities: a booking is an Event and the reserved space is a
# Facility linked through EventFacilityAppointment. This reuses the existing
# domain instead of adding a separate reservation table.
# Docs: docs/OPERATIONS.md, docs/EVENTS.md
class Booking::ConsoleService
  TIMELINE_START_HOUR = 8
  TIMELINE_END_HOUR = 18
  EQUIPMENT_PATTERN = /equipment|device|camera|microphone|mic\b|projector|screen|beamer|vr\b|polycom|av\b/i
  HOT_DESK_PATTERN = /desk|pod|booth|focus/i

  def self.call(company:, appointment:, now: Time.current, date: nil)
    new(company: company, appointment: appointment, now: now, date: date).call
  end

  def initialize(company:, appointment:, now:, date:)
    @company = company
    @appointment = appointment
    @branch = appointment.branch
    @now = now
    @date = date || now.to_date
  end

  def call
    {
      date: date.iso8601,
      timeline: { start_hour: TIMELINE_START_HOUR, end_hour: TIMELINE_END_HOUR },
      resources: resources,
      bookings: bookings,
      upcoming: upcoming,
      counts: counts
    }
  end

  private

  attr_reader :company, :appointment, :branch, :now, :date

  def facilities
    @facilities ||= company.facilities
      .where("branch_id = ? OR branch_id IS NULL", branch.id)
      .includes(:category)
      .order(:name)
      .limit(100)
      .to_a
  end

  def events
    @events ||= begin
      day_start = date.beginning_of_day
      day_end = day_start + 1.day

      company.events
        .where(branch_id: branch.id)
        .where("start_at >= :start AND start_at < :end", start: day_start, end: day_end)
        .where.not(workflow_status: :cancelled)
        .includes(
          :category,
          customer_event_appointments: :customer,
          employee_event_appointments: :employee,
          event_facility_appointments: :facility
        )
        .order(:start_at)
        .limit(200)
        .to_a
    end
  end

  def bookings
    @bookings ||= events.map { |event| booking_payload(event) }
  end

  def resources
    @resources ||= facilities.map { |facility| resource_payload(facility) }
  end

  def resource_payload(facility)
    category = facility.category&.name
    category = nil if category == "Facilities"

    {
      id: facility.id,
      name: facility.name,
      code: facility.code,
      category: category,
      capacity: facility.property_integer_1,
      status: resource_busy?(facility) ? "busy" : "available"
    }
  end

  def resource_busy?(facility)
    bookings.any? do |booking|
      booking[:resource_ids].include?(facility.id) && booking[:status] == "active"
    end
  end

  def booking_payload(event)
    customer = event.customer_event_appointments.first&.customer
    host = event.employee_event_appointments.first&.employee
    facility_ids = event.event_facility_appointments.map(&:facility_id)

    {
      id: event.id,
      title: event.name,
      code: event.code,
      category: event.category&.name,
      resource_ids: facility_ids,
      start_at: event.start_at&.iso8601,
      end_at: event.end_at&.iso8601,
      start_label: format_time(event.start_at),
      end_label: format_time(event.end_at),
      organizer: host&.name.presence || customer&.name.presence || "—",
      customer: customer&.name,
      attendees: event.customer_event_appointments.length + event.employee_event_appointments.length,
      status: booking_status(event),
      workflow_status: event.workflow_status
    }
  end

  def booking_status(event)
    return "cancelled" if event.workflow_status_cancelled?
    return "active" if event.workflow_status_in_progress?
    return "completed" if event.workflow_status_completed?

    if event.start_at && event.end_at && event.start_at <= now && event.end_at >= now
      "active"
    elsif event.end_at && event.end_at < now
      "completed"
    else
      "upcoming"
    end
  end

  def upcoming
    @upcoming ||= bookings
      .select { |booking| %w[upcoming active].include?(booking[:status]) && booking[:start_at].present? }
      .sort_by { |booking| booking[:start_at] }
      .first(5)
      .map do |booking|
        resource = facilities.find { |facility| booking[:resource_ids].include?(facility.id) }
        booking.merge(resource_name: resource&.name || "—")
      end
  end

  def counts
    @counts ||= begin
      used_facility_ids = bookings.flat_map { |booking| booking[:resource_ids] }.uniq
      equipment_resources = resources.select { |resource| searchable_resource_text(resource).match?(EQUIPMENT_PATTERN) }
      hot_desk_resources = resources.select { |resource| searchable_resource_text(resource).match?(HOT_DESK_PATTERN) }
      rooms_in_use = resources.count { |resource| resource[:status] == "busy" }

      {
        total_bookings_today: bookings.length,
        pending_checkin: bookings.count { |booking| booking[:status] == "upcoming" },
        resources_total: resources.length,
        resources_in_use: rooms_in_use,
        room_utilization: resources.empty? ? 0 : ((rooms_in_use.to_f / resources.length) * 100).round,
        equipment_deployed: equipment_resources.count { |resource| used_facility_ids.include?(resource[:id]) },
        equipment_total: equipment_resources.length,
        hot_desk_occupied: hot_desk_resources.count { |resource| resource[:status] == "busy" },
        hot_desk_total: hot_desk_resources.length
      }
    end
  end

  def searchable_resource_text(resource)
    [ resource[:category], resource[:name] ].compact.join(" ")
  end

  def format_time(time)
    return "—" if time.blank?

    time.strftime("%-I:%M %p")
  end
end
