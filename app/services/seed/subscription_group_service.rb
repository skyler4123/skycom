class Seed::SubscriptionGroupService
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
    SubscriptionGroup.new(
      company: company,
      branch: branch,
      name: name || "Subscription Group #{Faker::Lorem.sentence(word_count: 2)}",
      description: description || Faker::Lorem.sentence(word_count: 10),
      code: code || "SUBG-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || SubscriptionGroup.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || SubscriptionGroup.workflow_statuses.keys.sample,
      business_type: business_type || SubscriptionGroup.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    group = new(...)
    group.save!
    group
  end
end
