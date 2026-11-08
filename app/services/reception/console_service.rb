# frozen_string_literal: true

# Reception::ConsoleService — builds the live reception console payload for a
# branch appointment:
#
# - visits: today's Events (plus any still checked in from earlier) mapped to
#   the lobby/inside/departed buckets from workflow_status
# - parcels: Events flagged `metadata["reception_kind"] = "parcel"` and still
#   awaiting pickup
# - rooms: branch Facilities whose current/next Event decides availability
# - next_appointments: the next scheduled Events for the right-hand panel
#
# Why Events: the reception screen coordinates real bookings, so the visit is
# the Event and the visitor/host/room are its atomic appointment rows.
# Docs: docs/OPERATIONS.md, docs/EVENTS.md
class Reception::ConsoleService
  ROOM_CATEGORY_PATTERN = /room|suite|pod|board|conference|meeting|hall|desk/i

  def self.call(company:, appointment:, now: Time.current)
    new(company: company, appointment: appointment, now: now).call
  end

  def initialize(company:, appointment:, now:)
    @company = company
    @appointment = appointment
    @branch = appointment.branch
    @now = now
  end

  def call
    {
      visits: visits.map { |event| visit_payload(event) },
      parcels: parcels.map { |event| parcel_payload(event) },
      rooms: rooms,
      appointments: next_appointments,
      counts: counts
    }
  end

  private

  attr_reader :company, :appointment, :branch, :now

  def base_events
    @base_events ||= company.events.where(branch_id: branch.id)
  end

  def parcels
    @parcels ||= base_events
      .where("metadata ->> 'reception_kind' = ?", "parcel")
      .where.not(workflow_status: %i[completed cancelled])
      .includes(employee_event_appointments: :employee)
      .order(created_at: :desc)
      .limit(50)
      .to_a
  end

  def visits
    @visits ||= begin
      day_start = now.beginning_of_day
      day_end = day_start + 1.day
      scope = base_events
        .where.not(id: parcels.map(&:id))
        .where(
          "start_at >= :start AND start_at < :end OR workflow_status IN (:statuses)",
          start: day_start,
          end: day_end,
          statuses: [ Event.workflow_statuses.fetch("confirmed"), Event.workflow_statuses.fetch("in_progress") ]
        )
        .where.not(workflow_status: :cancelled)
        .includes(
          :category,
          customer_event_appointments: :customer,
          employee_event_appointments: { employee: :category },
          event_facility_appointments: :facility
        )
        .order(:start_at)
        .limit(200)

      scope.to_a
    end
  end

  def visit_payload(event)
    customer = event.customer_event_appointments.first&.customer
    host = event.employee_event_appointments.first&.employee
    facility = event.event_facility_appointments.first&.facility
    status = visit_status(event)
    note_key, note_time = visit_note(event, status)
    kind = event.metadata&.dig("visitor_kind").presence || event.category&.name.presence
    kind = "Visit" if kind.blank? || kind == "Events"
    host_role = host&.category&.name.presence
    host_role = "Host" if host_role.blank? || host_role == "Employees"

    {
      id: event.id,
      event_id: event.id,
      name: customer&.name.presence || event.name,
      company: event.metadata&.dig("visitor_company").presence || customer&.description.presence || "—",
      host: host&.name.presence || "—",
      hostRole: host_role,
      kind: kind,
      badge: event.code.presence || "V-#{event.id.to_s.first(6).upcase}",
      status: status,
      arrival: format_time(event.start_at),
      waitMin: wait_minutes(event, status),
      note_key: note_key,
      note_time: note_time,
      vip: event.metadata&.dig("vip") == true,
      zone: facility&.name.presence || event.metadata&.dig("zone").presence || "Reception",
      start_at: event.start_at&.iso8601,
      search: [
        customer&.name, customer&.description, event.metadata&.dig("visitor_company"),
        host&.name, event.code, event.category&.name, event.metadata&.dig("visitor_kind"),
        facility&.name, event.metadata&.dig("zone")
      ].compact.join(" ").downcase
    }
  end

  def parcel_payload(event)
    employee = event.employee_event_appointments.first&.employee
    metadata = event.metadata || {}
    locker = metadata["locker"].presence
    received_at = parse_time(metadata["received_at"])

    {
      id: event.id,
      event_id: event.id,
      carrier: metadata["carrier"].presence || "Parcel",
      title: metadata["item"].presence || event.name,
      recipient: employee&.name.presence || metadata["recipient_name"].presence || "—",
      location: locker || "Held at desk",
      received_at: received_at && format_time(received_at),
      tone: "primary",
      action: "Notify",
      workflow_status: event.workflow_status
    }
  end

  def rooms
    @rooms ||= begin
      facilities = company.facilities
        .where("branch_id = ? OR branch_id IS NULL", branch.id)
        .includes(:category)
        .order(:name)
        .limit(50)
        .to_a
      room_like = facilities.select { |facility| facility.category&.name.to_s.match?(ROOM_CATEGORY_PATTERN) }
      room_like = facilities if room_like.empty?

      room_like.first(8).map { |facility| room_payload(facility) }
    end
  end

  def room_payload(facility)
    facility_events = visits.select do |event|
      event.event_facility_appointments.any? { |link| link.facility_id == facility.id }
    end
    current = facility_events.find do |event|
      event.start_at && event.start_at <= now &&
        (event.end_at.nil? || event.end_at >= now) &&
        %w[confirmed in_progress].include?(event.workflow_status)
    end
    upcoming = facility_events
      .select { |event| event.start_at && event.start_at > now }
      .min_by(&:start_at)

    if current
      busy = current.workflow_status_in_progress?
      {
        id: facility.id,
        name: facility.name,
        capacity: facility.property_integer_1,
        status: busy ? "busy" : "reserved",
        time_label: format_time(busy ? current.end_at : current.start_at),
        detail: current.name
      }
    elsif upcoming
      {
        id: facility.id,
        name: facility.name,
        capacity: facility.property_integer_1,
        status: "reserved",
        time_label: format_time(upcoming.start_at),
        detail: upcoming.name
      }
    else
      {
        id: facility.id,
        name: facility.name,
        capacity: facility.property_integer_1,
        status: "available",
        time_label: nil,
        detail: nil
      }
    end
  end

  def next_appointments
    upcoming = visits
      .select { |event| event.start_at && event.start_at >= now && %w[pending confirmed].include?(event.workflow_status) }
      .sort_by(&:start_at)
      .first(5)

    upcoming.map do |event|
      customer = event.customer_event_appointments.first&.customer
      host = event.employee_event_appointments.first&.employee
      facility = event.event_facility_appointments.first&.facility

      {
        id: event.id,
        time: format_time(event.start_at),
        minutes_until: [ ((event.start_at - now) / 60).ceil, 0 ].max,
        title: customer&.name.presence || event.name,
        host: host&.name.presence || "—",
        room: facility&.name.presence || event.metadata&.dig("zone").presence || "—",
        status: appointment_status(event)
      }
    end
  end

  def counts
    {
      inside: visits.count { |event| visit_status(event) == "active" },
      lobby: visits.count { |event| visit_status(event) == "lobby" },
      departed: visits.count { |event| visit_status(event) == "departed" },
      expected_today: visits.count { |event| event.start_at && event.start_at >= now.beginning_of_day && event.start_at < now.beginning_of_day + 1.day },
      remaining: visits.count { |event| %w[lobby active upcoming].include?(visit_status(event)) },
      parcels: parcels.length,
      rooms_available: rooms.count { |room| room[:status] == "available" },
      rooms_total: rooms.length
    }
  end

  def visit_status(event)
    case event.workflow_status
    when "pending", "draft" then "upcoming"
    when "confirmed" then "lobby"
    when "in_progress" then "active"
    when "completed" then "departed"
    else "upcoming"
    end
  end

  def wait_minutes(event, status)
    return 0 unless status == "lobby" && event.start_at
    [ ((now - event.start_at) / 60).floor, 0 ].max
  end

  def visit_note(event, status)
    case status
    when "lobby"
      [ "waiting", nil ]
    when "active"
      checked_in = parse_time(event.metadata&.dig("checked_in_at"))
      checked_in ? [ "checked_in", format_time(checked_in) ] : [ "inside", nil ]
    when "departed"
      checked_out = parse_time(event.metadata&.dig("checked_out_at"))
      checked_out ? [ "checked_out", format_time(checked_out) ] : [ "completed", nil ]
    else
      [ "pre_registered", nil ]
    end
  end

  def appointment_status(event)
    case event.workflow_status
    when "pending" then "Scheduled"
    when "confirmed" then "Ready"
    when "in_progress" then "In progress"
    else "Scheduled"
    end
  end

  def parse_time(value)
    return nil if value.blank?
    Time.zone.parse(value.to_s)
  rescue ArgumentError
    nil
  end

  def format_time(time)
    return "—" if time.blank?
    time.strftime("%-I:%M %p")
  end
end
