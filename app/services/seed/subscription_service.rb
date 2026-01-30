class Seed::SubscriptionService
  def self.create(
    subscription_plan:,
    subscription_group: nil,
    price: nil,
    period:,
    seller:,
    buyer:,
    resource: nil,
    processer: nil,
    name: Faker::Company.name,
    description: Faker::Lorem.sentence(word_count: 10),
    country_code: Subscription.country_codes.keys.sample,
    timezone: Subscription.timezones.keys.sample,
    lifecycle_status: Subscription.lifecycle_statuses.keys.sample,
    workflow_status: Subscription.workflow_statuses.keys.sample,
    business_type: Subscription.business_types.keys.sample,
    auto_renew: false,
    discarded_at: nil,
    metadata: {}
  )
    Subscription.create!(
      subscription_plan: subscription_plan,
      subscription_group: subscription_group,
      price: price || subscription_plan.price,
      period: period,
      seller: seller,
      buyer: buyer,
      resource: resource,
      processer: processer,
      name: name,
      description: description,
      country_code: country_code,
      timezone: timezone,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type,
      auto_renew: auto_renew,
      discarded_at: discarded_at,
      metadata: metadata
    )
  end
end
