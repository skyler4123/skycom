# spec/factories/customer_reservation_appointments.rb
FactoryBot.define do
  factory :customer_reservation_appointment do
    association :company
    association :customer
    association :reservation
    business_type { :primary }
    lifecycle_status { :active }
    workflow_status { :draft }
  end
end
