class Seed::DepartmentAppointmentService
  def self.create(
    department:,
    appoint_to:
  )
    appointment = DepartmentAppointment.create!(
      department: department,
      appoint_to: appoint_to
    )
  end
end
