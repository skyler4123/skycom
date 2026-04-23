class Seed::PolicyService
  def self.new(
    branch:,
    name: nil,
    description: nil,
    resource: COMMON_RESOURCES.sample,
    action: COMMON_ACTIONS.sample,
    kind: nil,
    status: nil,
    discarded_at: nil,
    index: 1
  )
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..90).days : nil
    name ||= "#{action.capitalize} #{resource.titleize} Access Policy #{index + 1}"
    description ||= "Policy governing the #{action} access to #{resource}."
    kind ||= Policy.kinds.keys.sample
    status ||= Policy.statuses.keys.sample

    Policy.new(
      branch: branch,
      name: name,
      description: description,
      resource: resource.singularize,
      action: action,
      kind: kind,
      status: status,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    policy = new(...)
    policy.save!
    policy
  end
end
