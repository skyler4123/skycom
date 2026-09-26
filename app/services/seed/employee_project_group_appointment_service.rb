class Seed::EmployeeProjectGroupAppointmentService
  def self.new(
    company:,
    employee:,
    project_group:,
    name: nil,
    description: nil,
    code: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company, employee or project_group provided." if company.nil? || employee.nil? || project_group.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{employee.name} Appointment"

    EmployeeProjectGroupAppointment.new(
      company: company,
      employee: employee,
      project_group: project_group,
      name: name,
      description: description || "Employee appointment for #{employee.name}.",
      code: code || "EPG-#{SecureRandom.hex(4).upcase}",
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
