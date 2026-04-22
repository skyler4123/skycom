# spec/factories/subscriptions.rb
FactoryBot.define do
  factory :subscription do
    association :company
    association :subscription_plan, company: company
    association :subscription_group, company: company
    association :price, company: company
    association :period
    association :seller, factory: :company
    association :buyer, factory: :company

    name { "Subscription #{Faker::Lorem.sentence(word_count: 3)}" }
    description { Faker::Lorem.sentence(word_count: 10) }
    code { "SUB-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { Subscription.lifecycle_statuses.keys.sample }
    workflow_status { Subscription.workflow_statuses.keys.sample }
    country_code { Subscription.country_codes.keys.sample }
    timezone { Subscription.timezones.keys.sample }
    business_type { Subscription.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::SubscriptionService.create(
        company: company,
        subscription_plan: subscription_plan,
        subscription_group: subscription_group,
        price: price,
        period: period,
        seller: seller,
        buyer: buyer,
        name: name,
        description: description,
        code: code,
        lifecycle_status: lifecycle_status,
        workflow_status: workflow_status,
        country_code: country_code,
        timezone: timezone,
        business_type: business_type,
        discarded_at: discarded_at
      )
    end

    skip_create
  end
end
