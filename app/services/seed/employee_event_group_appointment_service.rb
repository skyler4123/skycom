class Seed::EmployeeEventGroupAppointmentService
  def self.new(
    company:,
    employee:,
    event_group:,
    name: nil,
    description: nil,
    code: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company, employee or event_group provided." if company.nil? || employee.nil? || event_group.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{employee.name} Appointment"

    EmployeeEventGroupAppointment.new(
      company: company,
      employee: employee,
      event_group: event_group,
      name: name,
      description: description || "Employee appointment for #{employee.name}.",
      code: code || "EEVG-#{SecureRandom.hex(4).upcase}",
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
