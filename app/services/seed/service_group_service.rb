class Seed::ServiceGroupService
  def self.new(
    branch:,
    name: "#{Faker::App.name} Service Group",
    description: "A group for #{Faker::Company.bs} services.",
    code: nil,
    workflow_status: nil,
    lifecycle_status: nil,
    business_type: ServiceGroup.business_types.keys.sample,
    discarded_at: nil
  )
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    code ||= "SG-#{branch.id}-#{SecureRandom.hex(3).upcase}"
    workflow_status ||= ServiceGroup.workflow_statuses.keys.sample
    lifecycle_status ||= ServiceGroup.lifecycle_statuses.keys.sample

    ServiceGroup.new(
      branch: branch,
      name: name,
      description: description,
      code: code,
      workflow_status: workflow_status,
      lifecycle_status: lifecycle_status,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    group = new(...)
    group.save!
    group
  end
end
