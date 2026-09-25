# spec/factories/address_department_appointments.rb
FactoryBot.define do
  factory :address_department_appointment do
    association :address
    association :department
    business_type { :office }
    lifecycle_status { :active }
    workflow_status { :approved }
  end
end
