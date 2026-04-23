class Seed::OrderGroupService
  def self.new(
    company:,
    branch: nil,
    customer: nil,
    name: nil,
    description: nil,
    code: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil
  )
    OrderGroup.new(
      company: company,
      branch: branch,
      customer: customer,
      name: name || Faker::Company.bs,
      description: description || Faker::Lorem.sentence(word_count: 10),
      code: code || "OG-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || OrderGroup.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || OrderGroup.workflow_statuses.keys.sample,
      business_type: business_type || OrderGroup.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    group = new(...)
    group.save!
    group
  end
end
