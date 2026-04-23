class Seed::DocumentGroupAppointmentService
  def self.new(
    company:,
    document_group:,
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
    raise "Cannot create appointment: No company or document_group provided." if company.nil? || document_group.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{document_group.name} Appointment"

    DocumentGroupAppointment.new(
      company: company,
      document_group: document_group,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      appoint_for: appoint_for,
      appoint_by: appoint_by,
      name: name,
      description: description || "Document group appointment for #{document_group.name}.",
      code: code || "DGR-APT-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || DocumentGroupAppointment.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || DocumentGroupAppointment.workflow_statuses.keys.sample,
      business_type: business_type || DocumentGroupAppointment.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
