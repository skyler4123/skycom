class Seed::ProjectGroupAppointmentService
  def self.create(
    company:,
    project_group:,
    appoint_from: nil,
    appoint_to:,
    appoint_for: nil,
    appoint_by: nil,
    name: nil,
    description: nil,
    code: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company or project_group provided." if company.nil? || project_group.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{project_group.name} Appointment"

    ProjectGroupAppointment.create!(
      company: company,
      project_group: project_group,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      appoint_for: appoint_for,
      appoint_by: appoint_by,
      name: name,
      description: description || "Project group appointment for #{project_group.name}.",
      code: code || "PJGR-APT-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || ProjectGroupAppointment.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || ProjectGroupAppointment.workflow_statuses.keys.sample,
      business_type: business_type || ProjectGroupAppointment.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
