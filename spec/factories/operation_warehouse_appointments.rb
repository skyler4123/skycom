# spec/factories/operation_warehouse_appointments.rb
FactoryBot.define do
  factory :operation_warehouse_appointment do
    association :company
    operation { association :operation, company: company, operation_type: :inventory }
    warehouse { association :warehouse, company: company }

    trait :inactive do
      workflow_status { :inactive }
    end
  end
end
