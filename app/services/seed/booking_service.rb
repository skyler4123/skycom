# This service seeds the database with Booking records. Each booking connects
# a "booker" (e.g., an Employee) to a "bookable" resource (e.g., a Facility)
# within the context of a Company.

class Seed::BookingService
  def self.create(
    company:,
    appoint_from: nil,
    appoint_to:,
    name: Faker::Book.title,
    description: Faker::Lorem.sentence,
    code: Faker::Code.npi,
    lifecycle_status: Booking.lifecycle_statuses.keys.sample,
    workflow_status: Booking.workflow_statuses.keys.sample,
    business_type: Booking.business_types.keys.sample,
    discarded_at: nil
  )
    appoint_from ||= company.employees.sample

    Booking.create!(
      company: company,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      name: name,
      description: description,
      code: code,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end
end
