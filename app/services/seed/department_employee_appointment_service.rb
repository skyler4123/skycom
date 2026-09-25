class Seed::DepartmentEmployeeAppointmentService
  def self.new(
    company:,
    department:,
    employee:,
    name: nil,
    description: nil,
    code: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company, department or employee provided." if company.nil? || department.nil? || employee.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{department.name} Appointment"

    DepartmentEmployeeAppointment.new(
      company: company,
      department: department,
      employee: employee,
      name: name,
      description: description || "Department appointment for #{department.name}.",
      code: code || "DEPT-EMP-#{SecureRandom.hex(4).upcase}",
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
