class Seed::EventGroupAppointmentService
  def self.new(
    company:,
    event_group:,
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
    raise "Cannot create appointment: No company or event_group provided." if company.nil? || event_group.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{event_group.name} Appointment"

    EventGroupAppointment.new(
      company: company,
      event_group: event_group,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      appoint_for: appoint_for,
      appoint_by: appoint_by,
      name: name,
      description: description || "Event group appointment for #{event_group.name}.",
      code: code || "EVGR-APT-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || EventGroupAppointment.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || EventGroupAppointment.workflow_statuses.keys.sample,
      business_type: business_type || EventGroupAppointment.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
