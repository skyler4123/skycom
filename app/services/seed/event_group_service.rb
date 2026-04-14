class Seed::EventGroupService
  def self.create(
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
    EventGroup.create!(
      company: company,
      branch: branch,
      name: name || "Event Group #{Faker::Lorem.sentence(word_count: 2)}",
      description: description || Faker::Lorem.sentence(word_count: 10),
      code: code || "EG-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || EventGroup.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || EventGroup.workflow_statuses.keys.sample,
      business_type: business_type || EventGroup.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
