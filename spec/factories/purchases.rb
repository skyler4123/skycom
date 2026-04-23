# spec/factories/purchases.rb
FactoryBot.define do
  factory :purchase do
    association :company

    name { "Purchase #{Faker::Lorem.sentence(word_count: 3)}" }
    description { Faker::Lorem.sentence(word_count: 10) }
    code { "PUR-#{SecureRandom.hex(4).upcase}" }
    status { Purchase.statuses.keys.sample }
    business_type { Purchase.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::PurchaseService.new(
        company: company,
        name: name,
        description: description,
        code: code,
        status: status,
        business_type: business_type,
        discarded_at: discarded_at
      )
    end

  end
end
