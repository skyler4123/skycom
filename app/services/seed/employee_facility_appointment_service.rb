class Seed::EmployeeFacilityAppointmentService
  def self.new(
    company:,
    employee:,
    facility:,
    name: nil,
    description: nil,
    code: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company, employee or facility provided." if company.nil? || employee.nil? || facility.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{employee.name} Appointment"

    EmployeeFacilityAppointment.new(
      company: company,
      employee: employee,
      facility: facility,
      name: name,
      description: description || "Employee appointment for #{employee.name}.",
      code: code || "EMP-FAC-#{SecureRandom.hex(4).upcase}",
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
