class Seed::PolicyAppointmentService
  def self.create(
    company:,
    policy:,
    appoint_to:,
    workflow_status: :active
  )
    PolicyAppointment.create!(
      company: company,
      policy: policy,
      appoint_to: appoint_to,
      workflow_status: workflow_status
    )
  end
end
