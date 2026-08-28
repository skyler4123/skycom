# app/services/seed/setting_service.rb
class Seed::SettingService
  def self.new(
    appoint_to: nil,
    company: nil,
    setting_group: nil,
    name: "Default settings",
    description: nil,
    code: nil,
    metadata: {},
    lifecycle_status: :active,
    workflow_status: :confirmed,
    business_type: :system,
    discarded_at: nil
  )
    appoint_to ||= company
    company ||= appoint_to.respond_to?(:company) ? appoint_to.company : appoint_to

    Setting.new(
      setting_group: setting_group,
      company: company,
      appoint_to: appoint_to,
      name: name,
      description: description,
      code: code || "SETTING-#{SecureRandom.hex(4).upcase}",
      metadata: metadata,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    setting = new(...)
    setting.save!
    setting
  end
end
