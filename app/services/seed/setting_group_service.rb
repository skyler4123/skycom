class Seed::SettingGroupService
  def self.new(
    company:,
    branch: nil,
    name: nil,
    description: nil,
    code: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil
  )
    SettingGroup.new(
      company: company,
      branch: branch,
      name: name || "Setting Group #{Faker::Lorem.sentence(word_count: 2)}",
      description: description || Faker::Lorem.sentence(word_count: 10),
      code: code || "SG-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || SettingGroup.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || SettingGroup.workflow_statuses.keys.sample,
      business_type: business_type || SettingGroup.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    group = new(...)
    group.save!
    group
  end
end
