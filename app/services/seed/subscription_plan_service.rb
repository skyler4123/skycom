module Seed
  class SubscriptionPlanService

    # Helper method for individual creation
    def self.create(
      company:,
      branch: nil,
      price:,
      duration_days:,
      name:,
      code: "#{company.id}_#{name.parameterize}",
      lifecycle_status: :active,
      workflow_status: :published
      )
      SubscriptionPlan.create!(
        company: company,
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