# spec: docs/CALENDAR.md — a seeded booking.
#
# Goes through Calendar::BookingService, NOT CalendarEvent.create!, so the seeder
# obeys exactly the same hard-block conflict validation as the API. A seeder that
# bypassed it would happily produce a double-booked demo dataset that the UI
# then refuses to edit.
class Seed::CalendarEventService
  def self.create(
    company:,
    calendar_procedure:,
    practitioner_ids: [],
    location_ids: [],
    equipment_ids: [],
    participant_ids: [],
    title: nil,
    starts_at:,
    status: :confirmed,
    **overrides
  )
    Calendar::BookingService.create(
      company: company,
      attributes: {
        calendar_procedure: calendar_procedure,
        title: title || calendar_procedure.name,
        starts_at: starts_at,
        ends_at: starts_at + calendar_procedure.duration_minutes.minutes,
        timezone: "UTC",
        status: status
      }.merge(overrides),
      practitioner_ids: practitioner_ids,
      location_ids: location_ids,
      equipment_ids: equipment_ids,
      participant_ids: participant_ids
    )
  end
end
