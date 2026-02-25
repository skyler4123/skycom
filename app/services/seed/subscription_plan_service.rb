module Seed
  class SubscriptionPlanService

    # Helper method for individual creation
    def self.create(
      company_group:,
      branch: nil,
      price:,
      duration_days:,
      name:,
      code: "#{company_group.id}_#{name.parameterize}",
      lifecycle_status: :active,
      workflow_status: :published
      )
      SubscriptionPlan.create!(
        company_group: company_group,
        branch: branch,
        price: price,
        duration_days: duration_days,
        name: name,
        code: code,
        lifecycle_status: lifecycle_status,
        workflow_status: workflow_status
      )
    end
  end
end