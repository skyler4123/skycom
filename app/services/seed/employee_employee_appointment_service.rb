class Seed::EmployeeEmployeeAppointmentService
  def self.new(
    company:,
    employee:,
    related_employee:,
    name: nil,
    description: nil,
    code: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company, employee or related_employee provided." if company.nil? || employee.nil? || related_employee.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{employee.name} Appointment"

    EmployeeEmployeeAppointment.new(
      company: company,
      employee: employee,
      related_employee: related_employee,
      name: name,
      description: description || "Employee appointment for #{employee.name}.",
      code: code || "EMP-EMP-#{SecureRandom.hex(4).upcase}",
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
