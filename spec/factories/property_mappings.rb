# spec/factories/property_mappings.rb
FactoryBot.define do
  factory :property_mapping do
    association :company

    name { "Test mappings" }
  end
end
