class Seed::EmployeeGroupAppointmentService
  def self.create(
    employee_group:,
    appoint_to:
  )
    appointment = EmployeeGroupAppointment.create!(
      employee_group: employee_group,
      appoint_to: appoint_to
    )
  end
end
