class Seed::DepartmentAppointmentService
  def self.new(
    department:,
    appoint_to:
  )
    DepartmentAppointment.new(
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
