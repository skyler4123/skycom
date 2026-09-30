# spec/factories/calendar_procedures.rb
FactoryBot.define do
  factory :calendar_procedure do
    company { association :company }
    calendar_position { association :calendar_position, company: company }

    sequence(:name) { |n| "Procedure #{n}" }
    code { "PRC-#{SecureRandom.hex(3).upcase}" }
    sequence(:slug) { |n| "procedure-#{n}" }
    description { Faker::Lorem.sentence }
    duration_minutes { 30 }
    buffer_before_minutes { 0 }
    buffer_after_minutes { 0 }
    min_lead_minutes { 0 }
    color { "#6366f1" }
    requires_location { false }
    requires_equipment { false }
    requires_practitioners { 1 }
  end
end
