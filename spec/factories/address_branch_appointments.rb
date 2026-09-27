# spec/factories/address_branch_appointments.rb
FactoryBot.define do
  factory :address_branch_appointment do
    association :address
    association :branch
    business_type { :office }
    lifecycle_status { :active }
    workflow_status { :approved }
  end
end
