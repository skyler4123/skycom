module Seed
  class SubscriptionPlanService

    # Helper method for individual creation
    def self.create(
      company_group:,
      company: nil,
      price:,
      duration_days:,
      name:,
      code: "#{company_group.id}_#{name.parameterize}",,
      lifecycle_status: :active,
      workflow_status: :published,
      auto_renew: false,
    )
      SubscriptionPlan.create!(
        company_group: company_group,
        company: company,
        price: price,
        duration_days: duration_days,
        name: name,
        code: code,
        lifecycle_status: lifecycle_status,
        workflow_status: workflow_status,
        auto_renew: auto_renew
      )
    end
  end
end