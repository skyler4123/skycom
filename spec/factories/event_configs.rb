# spec/factories/event_configs.rb
FactoryBot.define do
  factory :event_config do
    association :company
    association :category
  end
end
