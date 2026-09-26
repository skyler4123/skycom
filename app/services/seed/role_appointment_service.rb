class Seed::RoleAppointmentService
  # Dispatches to the atomic pairwise table for the target, e.g.
  # Employee => EmployeeRoleAppointment, Customer => CustomerRoleAppointment.
  def self.create(
    company:,
    role:,
    appoint_to:,
    workflow_status: :active,
    business_type: nil,
    **attrs
  )
    appointment_class = "#{appoint_to.class.name}RoleAppointment".constantize
    appointment_class.create!(
      {
        company: company,
        role: role,
        "#{appoint_to.class.name.underscore}_id" => appoint_to.id,
        workflow_status: workflow_status,
        business_type: business_type
      }.merge(attrs)
    )
  end
end
