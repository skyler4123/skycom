# spec/factories/event_config_logs.rb
FactoryBot.define do
  factory :event_config_log do
    association :company
    action { :created }
  end
end
