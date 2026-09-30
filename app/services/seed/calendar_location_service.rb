# spec: docs/CALENDAR.md — a bookable room or place, optionally a Facility.
class Seed::CalendarLocationService
  def self.new(
    company: nil,
    branch: nil,
    facility: nil,
    name: nil,
    code: nil,
    description: nil,
    capacity: 1,
    color: "#0ea5e9",
    bookable: true
  )
    CalendarLocation.new(
      company: company || facility&.company,
      branch: branch || facility&.branch,
      source_type: facility ? "Facility" : nil,
      source_id: facility&.id,
      name: name || facility&.name || "Room #{SecureRandom.hex(2).upcase}",
      code: code,
      description: description,
      capacity: capacity,
      color: color,
      bookable: bookable,
      lifecycle_status: :active
    )
  end

  def self.create(...)
    location = new(...)
    location.save!
    location
  end
end
