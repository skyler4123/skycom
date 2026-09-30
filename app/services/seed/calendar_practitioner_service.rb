# spec: docs/CALENDAR.md — a person who can be booked, bridged to a real Employee.
#
# The source pair is validated (source_type must be on the model's SOURCE_TYPES
# and source_id must resolve), so this service refuses to persist a dangling link.
class Seed::CalendarPractitionerService
  def self.new(
    company: nil,
    calendar_position: nil,
    employee: nil,
    branch: nil,
    name: nil,
    color: nil,
    bookable: true
  )
    CalendarPractitioner.new(
      company: company || employee&.company,
      calendar_position: calendar_position,
      branch: branch || employee&.branch,
      source_type: "Employee",
      source_id: employee&.id,
      name: name || employee&.name,
      color: color,
      bookable: bookable,
      lifecycle_status: :active
    )
  end

  def self.create(...)
    practitioner = new(...)
    raise ArgumentError, "CalendarPractitionerService requires an employee" if practitioner.source_id.blank?

    practitioner.save!
    practitioner
  end
end
