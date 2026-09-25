# spec/factories/address_employee_group_appointments.rb
FactoryBot.define do
  factory :address_employee_group_appointment do
    association :address
    association :employee_group
    business_type { :office }
    lifecycle_status { :active }
    workflow_status { :approved }
  end
end
