# spec/factories/property_mappings.rb
FactoryBot.define do
  factory :property_mapping do
    association :company
    association :category

    name { "Test mappings" }
  end
end
