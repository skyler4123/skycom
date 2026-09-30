# spec: docs/CALENDAR.md — bookable job positions ("Dentist", "Dental Assistant").
class Seed::CalendarPositionService
  def self.new(
    company: nil,
    name: Faker::Job.field,
    description: nil,
    color: "#6366f1",
    default_duration_minutes: 30,
    sort_order: 0
  )
    CalendarPosition.new(
      company: company,
      name: name,
      description: description,
      color: color,
      default_duration_minutes: default_duration_minutes,
      sort_order: sort_order,
      # Without an explicit lifecycle_status the record is nil, which the
      # CalendarPosition.bookable scope treats as active.
      lifecycle_status: :active
    )
  end

  def self.create(...)
    position = new(...)
    position.save!
    position
  end
end
