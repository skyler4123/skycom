class Seed::NotificationGroupAppointmentService
  def self.new(
    company:,
    notification_group:,
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
    raise "Cannot create appointment: No company or notification_group provided." if company.nil? || notification_group.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{notification_group.name} Appointment"

    NotificationGroupAppointment.new(
      company: company,
      notification_group: notification_group,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      appoint_for: appoint_for,
      appoint_by: appoint_by,
      name: name,
      description: description || "Notification group appointment for #{notification_group.name}.",
      code: code || "NGR-APT-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || NotificationGroupAppointment.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || NotificationGroupAppointment.workflow_statuses.keys.sample,
      business_type: business_type || NotificationGroupAppointment.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
