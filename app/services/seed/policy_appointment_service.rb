class Seed::PolicyAppointmentService
  # Creates a PolicyRoleAppointment (Policy assigned to Role).
  def self.create(
    company:,
    policy:,
    appoint_to:,
    workflow_status: :active,
    business_type: nil,
    **attrs
  )
    raise ArgumentError, "Policy appointments target roles, got #{appoint_to.class.name}" unless appoint_to.is_a?(Role)

    PolicyRoleAppointment.create!(
      {
        company: company,
        policy: policy,
        role: appoint_to,
        workflow_status: workflow_status,
        business_type: business_type
      }.merge(attrs)
    )
  end
end
