# spec/factories/address_customer_appointments.rb
FactoryBot.define do
  factory :address_customer_appointment do
    association :address
    association :customer
    business_type { :office }
    lifecycle_status { :active }
    workflow_status { :approved }
  end
end
