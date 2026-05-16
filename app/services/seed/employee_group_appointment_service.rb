class Seed::EmployeeGroupAppointmentService
  def self.create(
    company:,
    employee_group:,
    appoint_to:
  )
    appointment = EmployeeGroupAppointment.create!(
      company: company,
      employee_group: employee_group,
      appoint_to: appoint_to
    )
  end
end
