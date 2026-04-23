class Seed::RoleAppointmentService
  def self.create(
    company:,
    role:,
    appoint_to:,
    workflow_status: :active,
    business_type: nil
  )
    RoleAppointment.create!(
      company: company,
      role: role,
      appoint_to: appoint_to,
      workflow_status: workflow_status,
      business_type: business_type
    )
  end
end
