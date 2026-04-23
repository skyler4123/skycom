class Seed::ServiceAppointmentService
  def self.new(
    service:,
    appoint_to:
  )
    ServiceAppointment.new(
      service: service,
      appoint_to: appoint_to
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
