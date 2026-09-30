# spec: docs/CALENDAR.md — the person an appointment is for, optionally a Customer.
class Seed::CalendarParticipantService
  def self.new(
    company: nil,
    customer: nil,
    name: nil,
    code: nil,
    email: nil,
    phone_number: nil,
    notes: nil
  )
    CalendarParticipant.new(
      company: company || customer&.company,
      source_type: customer ? "Customer" : nil,
      source_id: customer&.id,
      name: name || customer&.name || Faker::Name.name,
      code: code,
      email: email || customer&.email,
      phone_number: phone_number || customer&.phone_number,
      notes: notes,
      lifecycle_status: :active
    )
  end

  def self.create(...)
    participant = new(...)
    participant.save!
    participant
  end
end
