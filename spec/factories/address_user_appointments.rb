# spec/factories/address_user_appointments.rb
FactoryBot.define do
  factory :address_user_appointment do
    association :address
    association :user
    business_type { :office }
    lifecycle_status { :active }
    workflow_status { :approved }
  end
end
