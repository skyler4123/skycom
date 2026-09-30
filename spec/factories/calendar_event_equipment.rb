# spec/factories/calendar_event_equipment.rb
FactoryBot.define do
  factory :calendar_event_equipment do
    calendar_event { association :calendar_event }
    company { calendar_event.company }
    calendar_equipment { association :calendar_equipment, company: company }

    role { "primary" }
    required { true }
  end
end
