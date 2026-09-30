# spec/factories/calendar_event_locations.rb
FactoryBot.define do
  factory :calendar_event_location do
    calendar_event { association :calendar_event }
    company { calendar_event.company }
    calendar_location { association :calendar_location, company: company }

    role { "primary" }
    required { true }
  end
end
