class Seed::CustomerGroupServiceAppointmentService
  def self.new(
    company:,
    customer_group:,
    service:,
    name: nil,
    description: nil,
    code: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company, customer_group or service provided." if company.nil? || customer_group.nil? || service.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{customer_group.name} Appointment"

    CustomerGroupServiceAppointment.new(
      company: company,
      customer_group: customer_group,
      service: service,
      name: name,
      description: description || "Customer group appointment for #{customer_group.name}.",
      code: code || "CGS-#{SecureRandom.hex(4).upcase}",
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
