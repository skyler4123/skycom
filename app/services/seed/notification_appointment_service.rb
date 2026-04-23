class Seed::NotificationAppointmentService
  def self.new(
    company:,
    notification:,
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
    raise "Cannot create appointment: No company or notification provided." if company.nil? || notification.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{notification.name} Appointment"

    NotificationAppointment.new(
      company: company,
      notification: notification,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      appoint_for: appoint_for,
      appoint_by: appoint_by,
      name: name,
      description: description || "Notification appointment for #{notification.name}.",
      code: code || "NOTIF-APT-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || NotificationAppointment.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || NotificationAppointment.workflow_statuses.keys.sample,
      business_type: business_type || NotificationAppointment.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
