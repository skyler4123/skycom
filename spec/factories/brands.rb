# spec/factories/brands.rb
FactoryBot.define do
  factory :brand do
    name { Faker::Company.name }
    description { Faker::Lorem.sentence(word_count: 15) }
    code { "BR-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { Brand.lifecycle_statuses.keys.sample }
    workflow_status { Brand.workflow_statuses.keys.sample }
    business_type { Brand.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::BrandService.create
    end

    skip_create
  end
end
