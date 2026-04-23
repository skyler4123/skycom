# spec/factories/payment_methods.rb
FactoryBot.define do
  factory :payment_method do
    name { Faker::Company.name }
    description { Faker::Lorem.sentence(word_count: 10) }
    code { "PM-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { PaymentMethod.lifecycle_statuses.keys.sample }
    workflow_status { PaymentMethod.workflow_statuses.keys.sample }
    business_type { PaymentMethod.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::PaymentMethodService.new(
        name: name,
        description: description,
        code: code,
        lifecycle_status: lifecycle_status,
        workflow_status: workflow_status,
        business_type: business_type,
        discarded_at: discarded_at
      )
    end
  end
end
