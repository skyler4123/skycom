# frozen_string_literal: true

# Reception::ConsoleService — builds the live reception console payload for a
# branch appointment:
#
# - visits: today's guest-linked visits plus any still in the lobby/inside from
#   earlier, mapped to expected/lobby/inside/departed
# - parcels: Events flagged `metadata["reception_kind"] = "parcel"` and still
#   awaiting pickup
# - rooms: room-like branch facilities, with current/next Event availability
# - appointments: today's facility Events that are not reception visits
# - counts: full-data counts, independent of the display caps
# - shift: this employee's scheduled shift covering now, or nil
#
# Why Events: the reception screen coordinates real bookings, so the visit is
# the Event and the visitor/host/room are its atomic appointment rows.
# Docs: docs/OPERATIONS.md, docs/EVENTS.md
class Reception::ConsoleService
  ROOM_CATEGORY_PATTERN = /room|suite|pod|board|conference|meeting|hall|desk/i
  VISIT_LIMIT = 200
  PARCEL_LIMIT = 200
  APPOINTMENT_LIMIT = 200

  def self.call(company:, appointment:, employee: nil, now: Time.current)
    new(company: company, appointment: appointment, employee: employee, now: now).call
  end

  def initialize(company:, appointment:, employee:, now:)
    @company = company
    @appointment = appointment
    @employee = employee
    @branch = appointment.branch
    @now = now
  end

  def call
    {
      visits: visits.map { |event| visit_payload(event) },
      parcels: parcels.map { |event| parcel_payload(event) },
      rooms: rooms,
      appointments: appointments.map { |event| appointment_payload(event) },
      counts: counts,
      shift: Reception::ShiftService.call(employee: employee, branch: branch, now: now),
      generated_at: now.utc.iso8601
    }
  end

  private

  attr_reader :company, :appointment, :employee, :branch, :now

  def base_events
    @base_events ||= company.events.where(branch_id: branch.id)
  end

  def day_range
    @day_range ||= LocalTime.day_range(LocalTime.today(branch, at: now), branch)
  end

  def live_statuses
    @live_statuses ||= [
      Event.workflow_statuses.fetch("confirmed"),
      Event.workflow_statuses.fetch("in_progress")
    ]
  end

  def visit_scope
    @visit_scope ||= base_events
      .where("metadata ->> 'reception_kind' = ?", "visit")
      .where.not(workflow_status: %i[cancelled])
      .where.not(start_at: nil)
      .where(id: CustomerEventAppointment.where(company_id: company.id).select(:event_id))
      .where(
        "(start_at >= :start AND start_at < :finish) OR workflow_status IN (:live)",
        start: day_range.begin, finish: day_range.end, live: live_statuses
      )
      .includes(
        :category,
        customer_event_appointments: :customer,
        employee_event_appointments: { employee: :category },
        event_facility_appointments: :facility
      )
      .order(:start_at)
  end

  def visits
    @visits ||= visit_scope.limit(VISIT_LIMIT).to_a
  end

  def waiting_parcel_scope
    @waiting_parcel_scope ||= base_events
      .where("metadata ->> 'reception_kind' = ?", "parcel")
      .where.not(workflow_status: %i[completed cancelled])
      .includes(employee_event_appointments: :employee)
      .order(created_at: :desc)
  end

  def parcels
    @parcels ||= waiting_parcel_scope.limit(PARCEL_LIMIT).to_a
  end

  def appointment_scope
    @appointment_scope ||= base_events
      .where(start_at: day_range)
      .where.not(workflow_status: %i[cancelled])
      .where(id: EventFacilityAppointment.where(company_id: company.id).select(:event_id))
      .where("COALESCE(metadata ->> 'reception_kind', '') NOT IN (?)", %w[visit parcel])
      .includes(
        :category,
        employee_event_appointments: { employee: :category },
        event_facility_appointments: :facility
      )
      .order(:start_at)
  end

  def appointments
    @appointments ||= appointment_scope.limit(APPOINTMENT_LIMIT).to_a
  end

  def rooms
    @rooms ||= begin
      facilities = company.facilities
        .where("branch_id = ? OR branch_id IS NULL", branch.id)
        .includes(:category)
        .order(:name)
        .to_a
      room_like = facilities.select { |facility| facility.category&.name.to_s.match?(ROOM_CATEGORY_PATTERN) }
      room_like = facilities if room_like.empty?

      room_like.map { |facility| room_payload(facility) }
    end
  end

  def room_events
    @room_events ||= base_events
      .where.not(workflow_status: %i[cancelled])
      .where.not(start_at: nil)
      .where(id: EventFacilityAppointment.where(company_id: company.id).select(:event_id))
      .where(
        "start_at < :finish AND (end_at IS NULL OR end_at > :start)",
        start: day_range.begin, finish: day_range.end
      )
      .includes(:event_facility_appointments)
      .to_a
  end

  def room_payload(facility)
    facility_events = room_events.select do |event|
      event.event_facility_appointments.any? { |link| link.facility_id == facility.id }
    end
    current = facility_events
      .select do |event|
        event.start_at <= now &&
          (event.end_at.nil? || event.end_at >= now) &&
          %w[pending confirmed in_progress].include?(event.workflow_status)
      end
      .sort_by { |event| event.workflow_status == "in_progress" ? 0 : 1 }
      .first
    upcoming = facility_events
      .select { |event| event.start_at > now }
      .min_by(&:start_at)

    if current
      busy = current.workflow_status_in_progress?
      {
        id: facility.id,
        name: facility.name,
        status: busy ? "busy" : "reserved",
        time_at: LocalTime.utc_iso(busy ? current.end_at : current.start_at),
        detail: current.name
      }
    elsif upcoming
      {
        id: facility.id,
        name: facility.name,
        status: "reserved",
        time_at: LocalTime.utc_iso(upcoming.start_at),
        detail: upcoming.name
      }
    else
      {
        id: facility.id,
        name: facility.name,
        status: "available",
        time_at: nil,
        detail: nil
      }
    end
  end

  def visit_payload(event)
    customer = event.customer_event_appointments.first&.customer
    host = event.employee_event_appointments.first&.employee
    facility = event.event_facility_appointments.first&.facility
    status = visit_status(event)
    lobby_time = effective_lobby_time(event)
    inside_time = effective_inside_time(event)
    checked_out = parse_time(event.metadata&.dig("checked_out_at"))
    notified = parse_time(event.metadata&.dig("host_notified_at"))
    host_role = host&.category&.name
    host_role = nil if host_role == "Employees"
    kind = event.metadata&.dig("visitor_kind").presence || "Visit"
    kind = "Visit" if kind == "Events"

    {
      id: event.id,
      event_id: event.id,
      name: customer&.name.presence || event.name,
      company: event.metadata&.dig("visitor_company").presence || customer&.description.presence,
      host: host&.name,
      hostRole: host_role,
      room: facility&.name,
      kind: kind,
      badge: event.code.presence || "V-#{event.id.to_s.first(6).upcase}",
      status: status,
      arrival_at: LocalTime.utc_iso(event.start_at),
      lobby_entered_at: LocalTime.utc_iso(lobby_time),
      inside_at: LocalTime.utc_iso(inside_time),
      checked_out_at: LocalTime.utc_iso(checked_out),
      notified_at: LocalTime.utc_iso(notified),
      wait_minutes: status == "lobby" ? minutes_since(lobby_time) : nil,
      inside_minutes: status == "active" ? minutes_since(inside_time) : nil,
      vip: event.metadata&.dig("vip") == true,
      can_notify: host.present? && %w[upcoming lobby].include?(status),
      can_print: %w[lobby active].include?(status),
      search: [
        customer&.name, customer&.description, event.metadata&.dig("visitor_company"),
        host&.name, event.code, event.name, kind, facility&.name
      ].compact.join(" ").downcase
    }
  end

  def parcel_payload(event)
    employee = event.employee_event_appointments.first&.employee
    metadata = event.metadata || {}
    received_at = parse_time(metadata["received_at"])
    notified_at = parse_time(metadata["notified_at"])

    {
      id: event.id,
      event_id: event.id,
      carrier: metadata["carrier"].presence || "Parcel",
      title: metadata["item"].presence || event.name,
      recipient: employee&.name.presence || metadata["recipient_name"].presence,
      code: event.code,
      location: "Held at desk",
      received_at: LocalTime.utc_iso(received_at),
      notified_at: LocalTime.utc_iso(notified_at),
      workflow_status: event.workflow_status,
      search: [
        metadata["carrier"], metadata["item"], metadata["recipient_name"],
        employee&.name, event.code, event.name
      ].compact.join(" ").downcase
    }
  end

  def appointment_payload(event)
    host = event.employee_event_appointments.first&.employee
    facility = event.event_facility_appointments.first&.facility

    {
      id: event.id,
      start_at: LocalTime.utc_iso(event.start_at),
      title: event.name,
      host: host&.name,
      room: facility&.name,
      status: appointment_status(event)
    }
  end

  def counts
    @counts ||= {
      inside: visit_scope.where(workflow_status: :in_progress).count,
      lobby: visit_scope.where(workflow_status: :confirmed).count,
      expected: visit_scope.where(workflow_status: %i[pending draft], start_at: day_range).count,
      departed: visit_scope.where(workflow_status: :completed).count,
      scheduled_today: visit_scope.where(start_at: day_range).count,
      parcels: waiting_parcel_scope.count,
      rooms_ready: rooms.count { |room| room[:status] == "available" },
      rooms_total: rooms.length,
      average_wait_minutes: average_wait_minutes,
      visits_capped: visit_scope.count > VISIT_LIMIT,
      parcels_capped: waiting_parcel_scope.count > PARCEL_LIMIT,
      appointments: appointment_scope.count,
      appointments_capped: appointment_scope.count > APPOINTMENT_LIMIT
    }
  end

  def average_wait_minutes
    waits = visit_scope.where(workflow_status: :confirmed).map do |event|
      minutes_since(effective_lobby_time(event))
    end
    return nil if waits.empty?

    (waits.sum.to_f / waits.size).round(1)
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

  def effective_lobby_time(event)
    effective_lobby_time_from(event.start_at, event.metadata || {})
  end

  def effective_lobby_time_from(start_at, metadata)
    parse_time(metadata["lobby_entered_at"]) ||
      parse_time(metadata["checked_in_at"]) ||
      start_at
  end

  def effective_inside_time(event)
    parse_time(event.metadata&.dig("inside_at")) ||
      parse_time(event.metadata&.dig("checked_in_at")) ||
      event.start_at
  end

  def minutes_since(value)
    return 0 unless value
    [ ((now - value) / 60).floor, 0 ].max
  end

  def appointment_status(event)
    case event.workflow_status
    when "pending", "draft" then "Scheduled"
    when "confirmed" then "Confirmed"
    when "in_progress" then "In progress"
    when "completed" then "Completed"
    else "Scheduled"
    end
  end

  def parse_time(value)
    return nil if value.blank?
    Time.zone.parse(value.to_s)
  rescue ArgumentError
    nil
  end
end
