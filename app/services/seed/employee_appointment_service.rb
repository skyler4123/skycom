class Seed::EmployeeAppointmentService
  def self.create(
    company:,
    employee:,
    appoint_from: nil,
    appoint_to:,
    appoint_for: nil,
    appoint_by: nil,
    name: nil,
    description: nil,
    code: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company or employee provided." if company.nil? || employee.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{employee.name} Appointment"

    EmployeeAppointment.create!(
      company: company,
      employee: employee,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      appoint_for: appoint_for,
      appoint_by: appoint_by,
      name: name,
      description: description || "Employee appointment for #{employee.name}.",
      code: code || "EMP-APT-#{SecureRandom.hex(4).upcase}",
      discarded_at: discarded_at
    )
  end
end
