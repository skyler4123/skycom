# spec/factories/calendar_event_practitioners.rb
FactoryBot.define do
  factory :calendar_event_practitioner do
    calendar_event { association :calendar_event }
    company { calendar_event.company }
    calendar_practitioner { association :calendar_practitioner, company: company }

    role { "lead" }
    required { true }
  end
end
