# app/services/calendar/booking_service.rb
#
# Transactional write path for a booking. Saves the CalendarEvent and replaces
# its four assignment sets atomically, so a booking is never left holding half
# its resources.
#
# Conflict detection lives in CalendarEvent's own validation, so this service
# never re-implements those rules — it only has to publish the incoming
# assignment ids before the save (so validation can see them) and translate a
# rejection into a typed error. The controller turns that into
# `errors: [...]` + HTTP 422 (docs/API_ERROR_FORMAT.md).
#
# Passing `nil` for an assignment set leaves it untouched; pass an array to
# replace it wholesale.
#
# @see docs/CALENDAR.md §5
class Calendar::BookingService
  class Error < StandardError
    # Validation messages, ready for the FE toast.
    attr_reader :messages

    def initialize(messages)
      @messages = Array(messages)
      super(@messages.to_sentence)
    end
  end

  # Raised when the only reason the save failed is a resource double-booking.
  class Conflict < Error; end

  # join model => [ ids writer, foreign key, default role, fallback role ]
  ASSIGNMENT_SETS = {
    CalendarEventPractitioner => [ :practitioner_ids, :calendar_practitioner_id, "lead", "assistant" ],
    CalendarEventLocation => [ :location_ids, :calendar_location_id, "primary", "secondary" ],
    CalendarEventEquipment => [ :equipment_ids, :calendar_equipment_id, "primary", "secondary" ],
    CalendarEventParticipant => [ :participant_ids, :calendar_participant_id, "primary", "secondary" ]
  }.freeze

  def self.create(company:, attributes:, **assignments)
    new(company: company, event: company.calendar_events.new(attributes)).call(nil, **assignments)
  end

  def self.update(calendar_event:, attributes:, **assignments)
    new(company: calendar_event.company, event: calendar_event).call(attributes, **assignments)
  end

  # Read-only preview for the booking form: shows the clash before the user
  # commits. Never writes.
  def self.preview_conflicts(company:, attributes:, practitioner_ids: [], location_ids: [],
                             equipment_ids: [], participant_ids: [], except_id: nil)
    event = company.calendar_events.new(attributes)
    event.practitioner_ids = practitioner_ids
    event.location_ids = location_ids
    event.equipment_ids = equipment_ids
    event.participant_ids = participant_ids
    Calendar::ConflictChecker.new(event, except_id: except_id).conflicts
  end

  def initialize(company:, event:)
    @company = company
    @event = event
  end

  def call(attributes = nil, **assignments)
    event.assign_attributes(attributes) if attributes.present?

    # Publish the incoming ids so the conflict validation sees them on a brand
    # new booking, before any join row exists.
    ASSIGNMENT_SETS.each do |(model, (writer, _fk, _default, _fallback))|
      ids = assignments[writer]
      next if ids.nil?

      event.public_send(:"#{writer}=", Array(ids).compact_blank)
    end

    CalendarEvent.transaction do
      event.save!
      # The event now has an id on both paths (create and update), so the join
      # rows can be written either way.
      persist_assignments(assignments)
    end

    event
  rescue ActiveRecord::RecordInvalid => e
    raise error_class_for(e), e.record.errors.full_messages
  end

  private

  attr_reader :company, :event

  def persist_assignments(assignments)
    ASSIGNMENT_SETS.each do |(model, (writer, foreign_key, default_role, fallback_role))|
      ids = assignments[writer]
      next if ids.nil?

      model.where(calendar_event_id: event.id).delete_all
      Array(ids).compact_blank.uniq.each_with_index do |id, index|
        model.create!(
          company_id: event.company_id,
          calendar_event_id: event.id,
          foreign_key => id,
          # The first pick is the lead / primary; the rest take the fallback role.
          role: index.zero? ? default_role : fallback_role
        )
      end
    end
  end

  def error_class_for(exception)
    record = exception.record
    return Error unless record.is_a?(CalendarEvent)
    return Error unless record.errors.any? { |error| conflict_message?(error.message) }

    Conflict
  end

  def conflict_message?(message)
    message.include?("is already booked")
  end
end
