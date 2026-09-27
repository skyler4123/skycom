# spec/factories/customer_membership_appointments.rb
FactoryBot.define do
  factory :customer_membership_appointment do
    association :company
    association :customer
    association :membership
    business_type { :primary }
    lifecycle_status { :active }
    workflow_status { :approved }
  end
end
