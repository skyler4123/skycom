class Seed::PolicyAppointmentService
  def self.create(
    company:,
    policy:,
    appoint_to:,
    workflow_status: :active,
    business_type: nil
  )
    PolicyAppointment.create!(
      company: company,
      policy: policy,
      appoint_to: appoint_to,
      workflow_status: workflow_status,
      business_type: business_type
    )
  end
end
