# spec/factories/address_company_appointments.rb
FactoryBot.define do
  factory :address_company_appointment do
    association :address
    association :company
    business_type { :office }
    lifecycle_status { :active }
    workflow_status { :approved }
  end
end
