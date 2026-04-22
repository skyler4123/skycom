class Seed::SettingGroupAppointmentService
  def self.create(
    company:,
    setting_group:,
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
    raise "Cannot create appointment: No company or setting_group provided." if company.nil? || setting_group.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{setting_group.name} Appointment"

    SettingGroupAppointment.create!(
      company: company,
      setting_group: setting_group,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      appoint_for: appoint_for,
      appoint_by: appoint_by,
      name: name,
      description: description || "Setting group appointment for #{setting_group.name}.",
      code: code || "STGR-APT-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || SettingGroupAppointment.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || SettingGroupAppointment.workflow_statuses.keys.sample,
      business_type: business_type || SettingGroupAppointment.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
