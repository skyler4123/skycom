class Seed::DocumentAppointmentService
  def self.new(
    company:,
    document:,
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
    raise "Cannot create appointment: No company or document provided." if company.nil? || document.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{document.name} Appointment"

    DocumentAppointment.new(
      company: company,
      document: document,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      appoint_for: appoint_for,
      appoint_by: appoint_by,
      name: name,
      description: description || "Document appointment for #{document.name}.",
      code: code || "DOC-APT-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || DocumentAppointment.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || DocumentAppointment.workflow_statuses.keys.sample,
      business_type: business_type || DocumentAppointment.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
