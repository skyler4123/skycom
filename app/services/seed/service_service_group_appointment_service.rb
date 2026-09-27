class Seed::ServiceServiceGroupAppointmentService
  def self.new(
    company:,
    service:,
    service_group:,
    name: nil,
    description: nil,
    code: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company, service or service_group provided." if company.nil? || service.nil? || service_group.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{service.name} Appointment"

    ServiceServiceGroupAppointment.new(
      company: company,
      service: service,
      service_group: service_group,
      name: name,
      description: description || "Service appointment for #{service.name}.",
      code: code || "SSG-#{SecureRandom.hex(4).upcase}",
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
