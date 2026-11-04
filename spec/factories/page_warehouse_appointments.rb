# spec/factories/page_warehouse_appointments.rb
FactoryBot.define do
  factory :page_warehouse_appointment do
    association :company
    page { association :page, company: company, page_type: :inventory }
    warehouse { association :warehouse, company: company }

    trait :inactive do
      workflow_status { :inactive }
    end
  end
end
