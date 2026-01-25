module Seed
  class SubscriptionPlanService

    # Helper method for individual creation
    def self.create(company_group:, company: nil, name:, price_amount:, days:)
      period = Seed::PeriodService.create(days: days)
      price = Price.find_or_create_by!(amount: price_amount, currency: company.country_code)

      SubscriptionPlan.create!(
        company_group: company_group,
        company: company,
        price: price,
        period: period,
        name: name,
        code: "#{company.id}_#{name.parameterize}",
        lifecycle_status: :active,
        workflow_status: :published,
        auto_renew: true
      )
    end
  end
end