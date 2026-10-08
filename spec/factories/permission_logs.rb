# spec/factories/permission_logs.rb
FactoryBot.define do
  factory :permission_log do
    association :company
    action { :granted }
  end
end
