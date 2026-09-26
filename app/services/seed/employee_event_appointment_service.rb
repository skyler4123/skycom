class Seed::EmployeeEventAppointmentService
  def self.new(
    company:,
    employee:,
    event:,
    name: nil,
    description: nil,
    code: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company, employee or event provided." if company.nil? || employee.nil? || event.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{employee.name} Appointment"

    EmployeeEventAppointment.new(
      company: company,
      employee: employee,
      event: event,
      name: name,
      description: description || "Employee appointment for #{employee.name}.",
      code: code || "EMP-EVT-#{SecureRandom.hex(4).upcase}",
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
