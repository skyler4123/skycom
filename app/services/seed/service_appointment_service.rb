# This service seeds the database with Service records, ensuring each service
# is associated with an existing Company. It uses enums defined in the Service
# model and simulates soft deletion for a portion of the records.

class Seed::ServiceAppointmentService
  def self.create(
    service:,
    appoint_to:
  )
    ServiceAppointment.create!(
      service: service,
      appoint_to: appoint_to
    )
  end
end
