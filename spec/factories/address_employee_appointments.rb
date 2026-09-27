# spec/factories/address_employee_appointments.rb
FactoryBot.define do
  factory :address_employee_appointment do
    association :address
    association :employee
    business_type { :office }
    lifecycle_status { :active }
    workflow_status { :approved }
  end
end
