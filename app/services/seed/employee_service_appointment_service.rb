class Seed::EmployeeServiceAppointmentService
  def self.new(
    company:,
    employee:,
    service:,
    duration: nil,
    start_at: nil,
    name: nil,
    description: nil,
    code: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company, employee or service provided." if company.nil? || employee.nil? || service.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{employee.name} Appointment"

    EmployeeServiceAppointment.new(
      company: company,
      employee: employee,
      service: service,
      duration: duration,
      start_at: start_at,
      name: name,
      description: description || "Employee appointment for #{employee.name}.",
      code: code || "EMP-SRV-#{SecureRandom.hex(4).upcase}",
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
