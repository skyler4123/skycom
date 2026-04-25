class Seed::PolicyService
  def self.new(
    company: nil,
    branch: nil,
    name: nil,
    description: nil,
    resource: nil,
    action: nil,
    business_type: nil,
    lifecycle_status: nil,
    discarded_at: nil
  )
    business_type ||= Policy.business_types.keys.sample
    lifecycle_status ||= Policy.lifecycle_statuses.keys.sample

    Policy.new(
      company: company || branch.company,
      branch: branch,
      name: name,
      description: description,
      resource: resource,
      action: action,
      business_type: business_type,
      lifecycle_status: lifecycle_status,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    policy = new(...)
    policy.save!
    policy
  end
end
