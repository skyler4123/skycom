class Seed::DepartmentAppointmentService
  def self.new(
    company:,
    department:,
    appoint_to:,
    name: nil,
    description: nil,
    code: nil,
    discarded_at: nil
  )
    Seed::DepartmentEmployeeAppointmentService.new(
      company: company,
      department: department,
      employee: appoint_to,
      name: name,
      description: description,
      code: code,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
