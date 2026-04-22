class Seed::SettingAppointmentService
  def self.create(
    company:,
    setting:,
    setting_group: nil,
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
    raise "Cannot create appointment: No company or setting provided." if company.nil? || setting.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{setting.name} Appointment"

    SettingAppointment.create!(
      company: company,
      setting: setting,
      setting_group: setting_group,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      appoint_for: appoint_for,
      appoint_by: appoint_by,
      name: name,
      description: description || "Setting appointment for #{setting.name}.",
      code: code || "SET-APT-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || SettingAppointment.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || SettingAppointment.workflow_statuses.keys.sample,
      business_type: business_type || SettingAppointment.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
