# spec/factories/attendance_config_logs.rb
FactoryBot.define do
  factory :attendance_config_log do
    association :company
    action { :created }
  end
end
