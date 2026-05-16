class Seed::DepartmentAppointmentService
  def self.new(
    company:,
    department:,
    appoint_to:
  )
    DepartmentAppointment.new(
      company: company,
      department: department,
      appoint_to: appoint_to
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
