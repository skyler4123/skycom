class Seed::ServiceAppointmentService
  def self.new(
    company:,
    service:,
    appoint_to:
  )
    ServiceAppointment.new(
      company: company,
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
