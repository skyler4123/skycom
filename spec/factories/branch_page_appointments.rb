# spec/factories/branch_page_appointments.rb
FactoryBot.define do
  factory :branch_page_appointment do
    association :company
    branch { association :branch, company: company }
    page { association :page, company: company }

    trait :inactive do
      workflow_status { :inactive }
    end
  end
end
