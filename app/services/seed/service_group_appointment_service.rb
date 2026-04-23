class Seed::ServiceGroupAppointmentService
  def self.new(
    company:,
    service_group:,
    appoint_from: nil,
    appoint_to:,
    appoint_for: nil,
    appoint_by: nil,
    name: nil,
    description: nil,
    code: nil,
    duration: nil,
    start_at: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company or service_group provided." if company.nil? || service_group.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{service_group.name} Appointment"

    ServiceGroupAppointment.new(
      company: company,
      service_group: service_group,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      appoint_for: appoint_for,
      appoint_by: appoint_by,
      name: name,
      description: description || "Service group appointment for #{service_group.name}.",
      code: code || "SGR-APT-#{SecureRandom.hex(4).upcase}",
      duration: duration || rand(30..180),
      start_at: start_at || Faker::Time.forward(days: 30),
      lifecycle_status: lifecycle_status || ServiceGroupAppointment.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || ServiceGroupAppointment.workflow_statuses.keys.sample,
      business_type: business_type || ServiceGroupAppointment.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
