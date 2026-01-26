# This service seeds the database with Policy records, ensuring each policy
# is associated with an existing Company. It uses the enums defined in the Policy model
# and simulates soft deletion.

class Seed::PolicyService
  def self.create(
    company:,
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

    Policy.create!(
      company: company,
      name: name || "#{action.capitalize} #{resource.titleize} Access Policy #{index + 1}",
      description: description || "Policy governing the #{action} access to #{resource}.",
      resource: resource.singularize,
      action: action,
      kind: kind || Policy.kinds.keys.sample,
      status: status || Policy.statuses.keys.sample,
      discarded_at: discarded_at
    )
  end
end
