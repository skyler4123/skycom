class Seed::EventAppointmentService
  def self.new(
    company:,
    event:,
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
    raise "Cannot create appointment: No company or event provided." if company.nil? || event.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{event.name} Appointment"

    EventAppointment.new(
      company: company,
      event: event,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      appoint_for: appoint_for,
      appoint_by: appoint_by,
      name: name,
      description: description || "Event appointment for #{event.name}.",
      code: code || "EVT-APT-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || EventAppointment.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || EventAppointment.workflow_statuses.keys.sample,
      business_type: business_type || EventAppointment.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
