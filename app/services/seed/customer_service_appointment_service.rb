class Seed::CustomerServiceAppointmentService
  def self.new(
    company:,
    customer:,
    service:,
    duration: nil,
    start_at: nil,
    name: nil,
    description: nil,
    code: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company, customer or service provided." if company.nil? || customer.nil? || service.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{customer.name} Appointment"

    CustomerServiceAppointment.new(
      company: company,
      customer: customer,
      service: service,
      duration: duration,
      start_at: start_at,
      name: name,
      description: description || "Customer appointment for #{customer.name}.",
      code: code || "CUST-SRV-#{SecureRandom.hex(4).upcase}",
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
