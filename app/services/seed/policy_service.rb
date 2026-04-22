# This service seeds the database with Policy records, ensuring each policy
# is associated with an existing Branch. It uses the enums defined in the Policy model
# and simulates soft deletion.

class Seed::PolicyService
  COMMON_RESOURCES = %w[Employee Customer Product Order Branch Department Role].freeze
  COMMON_ACTIONS = %w[create read update delete].freeze

  def self.create(
    branch:,
    name: nil,
    description: nil,
    resource: COMMON_RESOURCES.sample,
    action: COMMON_ACTIONS.sample,
    business_type: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    index: 1
  )
    name ||= "#{action.capitalize} #{resource.titleize} Access Policy #{index + 1}"
    description ||= "Policy governing the #{action} access to #{resource}."
    business_type ||= Policy.business_types.keys.sample
    lifecycle_status ||= Policy.lifecycle_statuses.keys.sample
    workflow_status ||= Policy.workflow_statuses.keys.sample

    Policy.create!(
      company: branch.company,
      branch: branch,
      name: name,
      description: description,
      resource: resource.singularize,
      action: action,
      business_type: business_type,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status
    )
  end
end
