# spec/factories/branch_operation_appointments.rb
FactoryBot.define do
  factory :branch_operation_appointment do
    association :company
    branch { association :branch, company: company }
    operation { association :operation, company: company }

    trait :inactive do
      workflow_status { :inactive }
    end
  end
end
