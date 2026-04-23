class Seed::SettingService
  def self.new(
    setting_group:,
    company: nil,
    branch: nil,
    name: Faker::Lorem.word,
    description: Faker::Lorem.sentence(word_count: 5),
    content: "",
    code: nil,
    lifecycle_status: Setting.lifecycle_statuses.keys.sample,
    workflow_status: Setting.workflow_statuses.keys.sample,
    business_type: Setting.business_types.keys.sample,
    discarded_at: nil
  )
    company ||= setting_group.company

    Setting.new(
      setting_group: setting_group,
      company: company,
      branch: branch,
      name: name,
      description: description,
      content: content,
      code: code || "SETTING-#{SecureRandom.hex(4).upcase}",
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
