# spec: docs/CALENDAR.md — a bookable device, optionally a Stock record.
class Seed::CalendarEquipmentService
  def self.new(
    company: nil,
    branch: nil,
    stock: nil,
    name: nil,
    code: nil,
    description: nil,
    quantity: 1,
    color: "#f59e0b",
    bookable: true
  )
    CalendarEquipment.new(
      company: company || stock&.company,
      branch: branch,
      source_type: stock ? "Stock" : nil,
      source_id: stock&.id,
      name: name || stock&.name || "Device #{SecureRandom.hex(2).upcase}",
      code: code,
      description: description,
      quantity: quantity,
      color: color,
      bookable: bookable,
      lifecycle_status: :active
    )
  end

  def self.create(...)
    equipment = new(...)
    equipment.save!
    equipment
  end
end
