# spec/factories/calendar_event_participants.rb
FactoryBot.define do
  factory :calendar_event_participant do
    calendar_event { association :calendar_event }
    company { calendar_event.company }
    calendar_participant { association :calendar_participant, company: company }

    role { "primary" }
    required { true }
  end
end
