# spec/factories/table_config_logs.rb
FactoryBot.define do
  factory :table_config_log do
    association :company
    action { :created }
  end
end
