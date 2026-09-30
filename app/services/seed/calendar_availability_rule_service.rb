# spec: docs/CALENDAR.md — raw weekly working hours for a practitioner or a room.
#
# Times are "HH:MM" wall-clock in the rule's timezone. v1 has no overnight spans:
# the DB CHECK constraint rejects end_time <= start_time.
class Seed::CalendarAvailabilityRuleService
  def self.new(
    company:,
    calendar_practitioner: nil,
    calendar_location: nil,
    name: nil,
    timezone: "UTC",
    days_of_week: [ 1, 2, 3, 4, 5 ],
    start_time: "09:00",
    end_time: "17:00",
    effective_from: nil,
    effective_to: nil,
    priority: 0,
    is_unavailable: false
  )
    CalendarAvailabilityRule.new(
      company: company,
      calendar_practitioner: calendar_practitioner,
      calendar_location: calendar_location,
      name: name || default_name(is_unavailable),
      timezone: timezone,
      days_of_week: Array(days_of_week).map(&:to_i),
      start_time: start_time,
      end_time: end_time,
      effective_from: effective_from,
      effective_to: effective_to,
      priority: priority,
      is_unavailable: is_unavailable,
      lifecycle_status: :active
    )
  end

  def self.create(...)
    rule = new(...)
    # Exactly one owner — the model validates this too, but failing here gives
    # the seeder a clearer message.
    if rule.calendar_practitioner_id.present? == rule.calendar_location_id.present?
      raise ArgumentError, "CalendarAvailabilityRuleService needs exactly one owner"
    end

    rule.save!
    rule
  end

  def self.default_name(is_unavailable)
    is_unavailable ? "Blackout" : "Working hours"
  end
  private_class_method :default_name
end
