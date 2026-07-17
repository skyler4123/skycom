class Seed::SubscriptionPlanAppointmentService
  def self.new(
    company:,
    branch: nil,
    subscription_plan:,
    subscription_group: nil,
    name: Faker::Company.name,
    description: Faker::Lorem.sentence(word_count: 10),
    country: SubscriptionPlanAppointment.countries.keys.sample,
    timezone: SubscriptionPlanAppointment.timezones.keys.sample,
    lifecycle_status: SubscriptionPlanAppointment.lifecycle_statuses.keys.sample,
    workflow_status: SubscriptionPlanAppointment.workflow_statuses.keys.sample,
    business_type: SubscriptionPlanAppointment.business_types.keys.sample,
    auto_renew: false,
    discarded_at: nil,
    metadata: {}
  )
    SubscriptionPlanAppointment.new(
      company: company,
      branch: branch,
      subscription_plan: subscription_plan,
      subscription_group: subscription_group,
      name: name,
      description: description,
      country: country,
      timezone: timezone,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type,
      auto_renew: auto_renew,
      discarded_at: discarded_at,
      metadata: metadata
    )
  end

  def self.create(...)
    subscription = new(...)
    subscription.save!
    subscription
  end
end
