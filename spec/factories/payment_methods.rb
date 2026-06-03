# spec/factories/payment_methods.rb
FactoryBot.define do
  factory :payment_method do
    name { Faker::Company.name }
    code { "PM-#{SecureRandom.hex(4).upcase}" }
    business_type { PaymentMethod.business_types.keys.sample }

    transient do
      pm_category { nil }
    end

    initialize_with do
      Seed::PaymentMethodService.new(name: name, code: code, business_type: business_type)
    end

    before(:create) do |record, evaluator|
      category = evaluator.pm_category || create(:category)
      record.category = category
      record.property_mapping = category.property_mapping
    end
  end
end
