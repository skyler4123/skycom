# spec/factories/address_customer_group_appointments.rb
FactoryBot.define do
  factory :address_customer_group_appointment do
    association :address
    association :customer_group
    business_type { :office }
    lifecycle_status { :active }
    workflow_status { :approved }
  end
end
