# app/services/calendar/conflict_checker.rb
#
# Overlap detection for a single CalendarEvent. Answers one question: does this
# booking collide with any other booking that shares one of its resources?
#
# Two events conflict when their half-open windows genuinely intersect:
#
#   existing.starts_at < candidate.ends_at AND existing.ends_at > candidate.starts_at
#
# Shared endpoints are NOT a conflict — 10:00–11:00 followed by 11:00–12:00 is
# a perfectly normal back-to-back booking. Only a partial overlap (10:00–11:30
# against 10:30–11:30) collides.
#
# Cancelled and no-show events are ignored: they release the resource.
#
# This runs from two places — the CalendarEvent validation (hard block on save)
# and the booking form's pre-flight (so the user sees the clash before
# submitting). Same rules either way.
#
# @see docs/CALENDAR.md §5
class Calendar::ConflictChecker
  # Returns a conflict descriptor ready to be turned into an ActiveModel error.
  #
  #   { attribute: :base, kind: :practitioner, resource_id:, resource_name:,
  #     event_id:, event_title:, starts_at:, ends_at:, message: "..." }
  #
  # `except_id` excludes a record from the probe. Needed by the edit pre-flight:
  # the booking being edited is matched by the same practitioner/room, and must
  # not report itself as its own conflict.
  def initialize(event, company: nil, except_id: nil)
    @event = event
    @company = company || event.company
    @except_id = except_id
  end

  def conflicts
    return [] unless overlap_probe_possible?

    @conflicts ||= resource_probes.flat_map { |probe| conflicts_for(probe) }
      # A practitioner double-booked across three overlapping events is one
      # problem, not three — collapse to one message per resource.
      .uniq { |conflict| [ conflict[:kind], conflict[:resource_id] ] }
  end

  def conflict?
    conflicts.any?
  end

  # Public so callers (and specs) can inspect the event under test and stage
  # pending assignment ids on it.
  attr_reader :company, :event, :except_id

  private

  def overlap_probe_possible?
    company.present? && event.starts_at.present? && event.ends_at.present? &&
      event.ends_at > event.starts_at && !event.cancelled?
  end

  # One probe per resource type.
  #
  #   join   — the has_many association on CalendarEvent, for `joins`
  #   table  — the join table name, for `where` (differs from `join` for the
  #            equipment table, which is `calendar_event_equipments` but is
  #            reached through the singular association `calendar_event_equipment`)
  #   owner  — the resource association on CalendarEvent, for `includes`
  def resource_probes
    [
      { kind: :practitioner, attribute: :base, ids: normalized(event.practitioner_ids),
        join: :calendar_event_practitioners, table: :calendar_event_practitioners,
        owner: :calendar_practitioners,
        filter: { calendar_practitioner_id: normalized(event.practitioner_ids) },
        label: "practitioner" },
      { kind: :location, attribute: :base, ids: normalized(event.location_ids),
        join: :calendar_event_locations, table: :calendar_event_locations,
        owner: :calendar_locations,
        filter: { calendar_location_id: normalized(event.location_ids) },
        label: "location" },
      { kind: :equipment, attribute: :base, ids: normalized(event.equipment_ids),
        join: :calendar_event_equipment, table: :calendar_event_equipments,
        owner: :calendar_equipment,
        filter: { calendar_equipment_id: normalized(event.equipment_ids) },
        label: "equipment" },
      { kind: :participant, attribute: :base, ids: normalized(event.participant_ids),
        join: :calendar_event_participants, table: :calendar_event_participants,
        owner: :calendar_participants,
        filter: { calendar_participant_id: normalized(event.participant_ids) },
        label: "participant" }
    ].reject { |probe| probe[:ids].empty? }
  end

  def normalized(ids)
    Array(ids).compact_blank.map(&:to_s)
  end

  def candidates_for(probe)
    CalendarEvent
      .joins(probe[:join])
      .where(probe[:table] => probe[:filter])
      .where(company_id: company.id, status: CalendarEvent::BLOCKING_STATUSES)
      .overlapping(event.starts_at, event.ends_at)
      .where.not(id: [ event.id, except_id ].compact)
      .includes(probe[:owner])
      .to_a
  end

  def conflicts_for(probe)
    candidates = candidates_for(probe)
    return [] if candidates.empty?

    wanted = probe[:ids].to_set

    candidates.filter_map do |candidate|
      owners = candidate.public_send(probe[:owner]).index_by { |r| r.id.to_s }
      # Report a resource once even when it is booked on several overlapping events.
      shared = (probe[:ids] & owners.keys).find { |id| wanted.include?(id) }
      next if shared.blank?

      name = owners[shared]&.name
      {
        attribute: probe[:attribute],
        kind: probe[:kind],
        resource_id: shared,
        resource_name: name,
        event_id: candidate.id,
        event_title: candidate.display_title,
        starts_at: candidate.starts_at,
        ends_at: candidate.ends_at,
        message: conflict_message(probe[:label], candidate, name)
      }
    end
  end

  def conflict_message(label, candidate, resource_name)
    label = label.to_s
    window = "#{format_time(candidate.starts_at)}–#{format_time(candidate.ends_at)}"
    subject = resource_name.presence || label

    "This #{label} is already booked (#{subject}, #{window} — \"#{candidate.display_title}\")"
  end

  def format_time(time)
    time&.strftime("%H:%M")
  end
end
